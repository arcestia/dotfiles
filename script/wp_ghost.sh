#!/bin/bash

# Ensure uinput is accessible
sudo chmod 666 /dev/uinput 2>/dev/null

# The text to type (Classic Lorem Ipsum)
LOREM="Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."

clear
echo "--- WhatPulse Lorem Ipsum Mode ---"
echo -n "How many times should I type the text? "
read REPEAT
echo -n "Speed (Keys Per Second, max 20 for realism): "
read KPS

# Calculate delay in milliseconds for ydotool (-d option)
# ydotool waits 'd' ms after key down AND after key up (2 * d per char)
# So for KPS keys per second: 1000 / (KPS * 2) = d
if [ "$KPS" -gt 0 ]; then
    DELAY=$(echo "1000 / ($KPS * 2)" | bc)
    # Allows 0ms delay for extremely high speeds
else
    DELAY=50 # Default fallback
fi

echo "----------------------------------"
echo "!! SWITCH TO AN EMPTY TEXT FILE NOW !!"
echo "Starting in 5 seconds..."
sleep 5

START_TIME=$(date +%s.%N)
TOTAL_CHARS=0

# Hide terminal cursor and disable local echo to prevent artifacts
tput civis
stty -echo

# Clean up input splitting
IFS=' ' read -r -a WORDS <<< "$LOREM"

BUFFER=""
BUFFER_LEN=0

# Dynamic Batch Sizing based on KPS
# Aim for ~2 seconds of typing per batch to amortize process overhead
# Avg word length ~6 chars (incl space)
# Batch = (KPS * 2) / 6 = KPS / 3
BATCH_SIZE=$(echo "$KPS / 3" | bc)
if [ "$BATCH_SIZE" -lt 5 ]; then BATCH_SIZE=5; fi
if [ "$BATCH_SIZE" -gt 500 ]; then BATCH_SIZE=500; fi # Safety cap

echo "Using batch size: $BATCH_SIZE words"

# Check for Turbo Mode binary
TURBO_BIN="./script/wp_turbo"
if [ ! -x "$TURBO_BIN" ]; then
    TURBO_BIN="./wp_turbo" # Fallback if running from script dir
fi

# Use Turbo Mode if available and speed is high (>50 KPS)
if [ -x "$TURBO_BIN" ] && [ "$KPS" -gt 50 ]; then
    USE_TURBO=1
    # Calculate delay in MICROseconds for C program
    # 1000000 / KPS = us per key
    # Half for press, half for release
    TURBO_DELAY_US=$(echo "1000000 / ($KPS * 2)" | bc)
    echo "Turbo Mode Enabled! Using native injector with ${TURBO_DELAY_US}us delay."
else
    USE_TURBO=0
fi

for ((j=1; j<=REPEAT; j++)); do
    for (( i=0; i<${#WORDS[@]}; i++ )); do
        word="${WORDS[$i]}"
        
        # Add space unless it's the very last word of the paragraph
        if [[ $i -lt $((${#WORDS[@]} - 1)) ]]; then
            TEXT="$word "
        else
            TEXT="$word"
        fi
        
        # Add to buffer
        BUFFER="${BUFFER}${TEXT}"
        BUFFER_LEN=$(($BUFFER_LEN + ${#TEXT}))
        
        # If buffer has enough words or it's the last word, type it
        if (( (i + 1) % BATCH_SIZE == 0 )) || (( i == ${#WORDS[@]} - 1 )); then
            # Type the buffer
            if [ "$USE_TURBO" -eq 1 ]; then
                "$TURBO_BIN" "$TURBO_DELAY_US" "$BUFFER"
            else
                ydotool type -d "$DELAY" "$BUFFER"
            fi
            
            # Update cumulative character count
            TOTAL_CHARS=$(($TOTAL_CHARS + $BUFFER_LEN))
            
            # Clear buffer
            BUFFER=""
            BUFFER_LEN=0
            
            # Update stats
            CURRENT_TIME=$(date +%s.%N)
            ELAPSED=$(echo "$CURRENT_TIME - $START_TIME" | bc)
            
            # Calculate speed (KPS)
            if (( $(echo "$ELAPSED > 0" | bc -l) )); then
                SPEED=$(echo "scale=2; $TOTAL_CHARS / $ELAPSED" | bc)
                echo -ne "\rReal Speed: $SPEED KPS | Chars: $TOTAL_CHARS\033[K"
            fi
        fi
    done

    # Optional: Press 'Enter' after each paragraph
    if [ "$USE_TURBO" -eq 1 ]; then
        "$TURBO_BIN" "$TURBO_DELAY_US" $'\n'
    else
        ydotool key 28:1 28:0
    fi
    
    # Count Enter as a keystroke
    TOTAL_CHARS=$(($TOTAL_CHARS + 1))
done

# Restore terminal settings
tput cnorm
stty echo

echo -e "\nTask Complete!"