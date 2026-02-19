#!/usr/bin/env python3
import argparse
import datetime
import json
import os
import random
import sys
import time
import getpass

# Try to import requests, if not available, print error
try:
    import requests
except ImportError:
    print("Error: 'requests' module is missing. Please install it using 'pip install requests'")
    sys.exit(1)

# Constants
API_URL = "https://codestats.net/api/my/pulses"
POPULAR_LANGUAGES = [
    "Python", "JavaScript", "TypeScript", "HTML", "CSS", "C", "C++", "C#",
    "Rust", "Go", "Java", "PHP", "Ruby", "Swift", "Kotlin", "Shell",
    "SQL", "Markdown", "JSON", "YAML", "Docker", "Terraform"
]

def get_local_timestamp(days_ago=0):
    """
    Returns the current local time (or days ago) in RFC 3339 format with timezone offset.
    Code::Stats requires local time with offset.
    """
    dt = datetime.datetime.now().astimezone()
    if days_ago > 0:
        dt = dt - datetime.timedelta(days=days_ago)
    return dt.isoformat()

def generate_xp(languages, min_xp, max_xp):
    """
    Generates a list of dictionaries for the pulse payload.
    """
    xps = []
    for lang in languages:
        xp_amount = random.randint(min_xp, max_xp)
        if xp_amount > 0:
            xps.append({"language": lang, "xp": xp_amount})
    return xps

def send_pulse(token, xps, timestamp, dry_run=False):
    """
    Sends the pulse to the Code::Stats API.
    """
    payload = {
        "coded_at": timestamp,
        "xps": xps
    }
    
    headers = {
        "Content-Type": "application/json",
        "X-API-Token": token,
        "User-Agent": "codestats-faker/1.0"
    }

    if dry_run:
        print(f"[Dry Run] Payload: {json.dumps(payload, indent=2)}")
        return True

    try:
        response = requests.post(API_URL, json=payload, headers=headers, timeout=10)
        if response.status_code == 201:
            print(f"[Success] Pulse sent for {timestamp}: {len(xps)} languages.")
            return True
        else:
            print(f"[Error] Failed to send pulse. Status: {response.status_code}")
            print(f"Response: {response.text}")
            return False
    except Exception as e:
        print(f"[Exception] Error sending pulse: {e}")
        return False

def interactive_wizard():
    print("=== Code::Stats Faker Wizard ===")
    
    # 1. API Token
    token = os.environ.get("CODESTATS_TOKEN")
    if token:
        use_env = input(f"Found token in env ({token[:5]}...). Use it? [Y/n]: ").strip().lower()
        if use_env == 'n':
            token = getpass.getpass("Enter your Code::Stats API Token: ").strip()
    else:
        token = getpass.getpass("Enter your Code::Stats API Token: ").strip()
        
    if not token:
        print("Error: Token is required.")
        sys.exit(1)

    # 2. Languages
    print("\nSelect Languages (comma separated numbers or type names):")
    for i, lang in enumerate(POPULAR_LANGUAGES, 1):
        print(f"{i}. {lang}", end="\t")
        if i % 4 == 0:
            print()
    print()
    
    lang_input = input("Languages: ").strip()
    selected_languages = []
    for item in lang_input.split(','):
        item = item.strip()
        if item.isdigit():
            idx = int(item) - 1
            if 0 <= idx < len(POPULAR_LANGUAGES):
                selected_languages.append(POPULAR_LANGUAGES[idx])
        elif item:
            selected_languages.append(item)
    
    if not selected_languages:
        print("No languages selected. Defaulting to Python.")
        selected_languages = ["Python"]
        
    print(f"Selected: {', '.join(selected_languages)}")

    # 3. XP Range
    try:
        min_xp = int(input("\nMin XP per pulse [10]: ") or 10)
        max_xp = int(input("Max XP per pulse [50]: ") or 50)
    except ValueError:
        print("Invalid number, using defaults 10-50")
        min_xp, max_xp = 10, 50

    # 4. Mode
    print("\nChoose Mode:")
    print("1. Single Pulse (Once)")
    print("2. Backfill (Fill past X days)")
    print("3. Watch (Loop continuously)")
    
    mode_choice = input("Mode [1]: ").strip()
    
    args = argparse.Namespace()
    args.token = token
    args.languages = selected_languages
    args.min_xp = min_xp
    args.max_xp = max_xp
    args.dry_run = False # Can ask if needed
    
    if mode_choice == '2':
        try:
            days = int(input("How many days to backfill? (Max 7) [7]: ") or 7)
            args.backfill_days = min(days, 7)
            args.mode = 'backfill'
            
            try:
                txp = input("Target Total XP (0 to disable) [0]: ").strip()
                if txp:
                    args.target_xp = int(txp)
                else:
                    args.target_xp = 0
            except ValueError:
                args.target_xp = 0
                
        except ValueError:
             args.backfill_days = 7
             args.mode = 'backfill'
             args.target_xp = 0
    elif mode_choice == '3':
        try:
           interval = int(input("Average interval in seconds [300]: ") or 300)
           args.loop_interval = interval
           args.mode = 'loop'
        except ValueError:
            args.loop_interval = 300
            args.mode = 'loop'
    else:
        args.mode = 'single'

    return args

def main():
    parser = argparse.ArgumentParser(description="Code::Stats Faker Script")
    parser.add_argument("--token", help="API Token")
    parser.add_argument("--languages", help="Comma separated list of languages")
    parser.add_argument("--min-xp", type=int, default=10, help="Min XP per language")
    parser.add_argument("--max-xp", type=int, default=50, help="Max XP per language")
    parser.add_argument("--dry-run", action="store_true", help="Print payload without sending")
    parser.add_argument("--loop", action="store_true", help="Run continuously")
    parser.add_argument("--backfill-days", type=int, help="Backfill data for the last N days (max 7)")
    parser.add_argument("--target-xp", type=int, help="Target total XP for backfill mode")
    
    # Check if any args are passed (excluding script name)
    if len(sys.argv) == 1:
        args = interactive_wizard()
    else:
        args = parser.parse_args()
        if not args.token:
            args.token = os.environ.get("CODESTATS_TOKEN")
            if not args.token:
                print("Error: Token required via --token or env CODESTATS_TOKEN")
                sys.exit(1)
        
        if args.languages:
            args.languages = [l.strip() for l in args.languages.split(',')]
        else:
            args.languages = ["Python"] # Default
            
        args.mode = 'single'
        if args.loop:
            args.mode = 'loop'
            args.loop_interval = 300 # Default for CLI loop
        elif args.backfill_days:
            args.mode = 'backfill'

    # EXECUTION
    print(f"Starting Code::Stats Faker in '{args.mode}' mode...")
    
    if args.mode == 'single':
        xps = generate_xp(args.languages, args.min_xp, args.max_xp)
        ts = get_local_timestamp()
        send_pulse(args.token, xps, ts, args.dry_run)
        
    elif args.mode == 'backfill':
        print(f"Backfilling last {args.backfill_days} days...")
        if args.target_xp:
             print(f"Goal: ~{args.target_xp} XP")
        
        now = datetime.datetime.now().astimezone()
        start_date = now - datetime.timedelta(days=args.backfill_days)
        
        # Calculate strategy
        avg_xp_per_pulse = (args.min_xp + args.max_xp) / 2
        # If languages are independent (each gets its own random), total per pulse is higher?
        # generate_xp returns a list. logic: "xps.append...". So total XP is sum of all langs.
        # Average total XP per pulse = avg_xp_per_pulse * len(languages)
        avg_total_xp_per_pulse = avg_xp_per_pulse * len(args.languages)
        
        if args.target_xp:
            estimated_pulses = int(args.target_xp / avg_total_xp_per_pulse)
            if estimated_pulses <= 0: estimated_pulses = 1
        else:
            # Default behavior if no target XP: One pulse every ~4 hours? 
            # Or just use a reasonable number of pulses per day, e.g. 10.
            estimated_pulses = args.backfill_days * 10
            
        total_seconds = (now - start_date).total_seconds()
        calculated_interval = total_seconds / estimated_pulses
        
        # Enforce minimum 5 minutes (300 seconds)
        if calculated_interval < 300:
            print(f"Warning: To reach target XP, interval would be {calculated_interval:.0f}s. Clamping to minimum 300s (5m).")
            print("You might not reach the full Target XP within the timeframe.")
            calculated_interval = 300
            
        print(f"Estimated pulses: {estimated_pulses}")
        print(f"Interval: ~{calculated_interval/60:.1f} minutes")
        
        current_sim_time = start_date
        current_total_xp = 0
        
        while current_sim_time < now:
            # Check target
            if args.target_xp and current_total_xp >= args.target_xp:
                print(f"Target XP ({args.target_xp}) reached!")
                break
                
            # Randomize interval slightly (+/- 10%) to look natural
            variance = calculated_interval * 0.1
            actual_interval = calculated_interval + random.uniform(-variance, variance)
            if actual_interval < 300: actual_interval = 300
            
            xps = generate_xp(args.languages, args.min_xp, args.max_xp)
            pulse_xp = sum(item['xp'] for item in xps)
            current_total_xp += pulse_xp
            
            ts = current_sim_time.isoformat()
            
            print(f"Sending backfill for {ts} (XP: {pulse_xp}, Total: {current_total_xp})...")
            if not send_pulse(args.token, xps, ts, args.dry_run):
                 # converting to simple sleep if error or just continue? 
                 # sending failure usually generic. continue.
                 pass
            
            # Advance time
            current_sim_time += datetime.timedelta(seconds=actual_interval)
            
            # Random sleep between requests to avoid rate limits/detection (5-10s)
            if not args.dry_run:
                delay = random.randint(5, 10)
                print(f"Waiting {delay}s...")
                time.sleep(delay)

    elif args.mode == 'loop':
        print("Press Ctrl+C to stop.")
        try:
            while True:
                xps = generate_xp(args.languages, args.min_xp, args.max_xp)
                ts = get_local_timestamp()
                send_pulse(args.token, xps, ts, args.dry_run)
                
                # Random sleep
                sleep_time = random.randint(args.loop_interval - 60, args.loop_interval + 60)
                if sleep_time < 10: sleep_time = 10
                print(f"Sleeping for {sleep_time} seconds...")
                time.sleep(sleep_time)
        except KeyboardInterrupt:
            print("\nStopped.")

if __name__ == "__main__":
    main()
