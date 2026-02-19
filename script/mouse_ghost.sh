#!/bin/bash

# Ensure uinput is accessible
sudo chmod 666 /dev/uinput 2>/dev/null

echo "=========================================="
echo "      MOUSE CLICK SPEED TESTER (Fedora)    "
echo "=========================================="

# 1. Inputs
echo "Select Action:"
echo "1) Left Click"
echo "2) Scroll UP"
echo "3) Scroll DOWN"
echo "4) Move UP"
echo "5) Move DOWN"
echo "6) Move LEFT"
echo "7) Move RIGHT"
echo "8) Random Move"
read -p "Choice (1-8): " ACTION

case $ACTION in
    2) MODE=1; ACTION_NAME="Scroll UP" ;;
    3) MODE=2; ACTION_NAME="Scroll DOWN" ;;
    4) MODE=3; ACTION_NAME="Move UP" ;;
    5) MODE=4; ACTION_NAME="Move DOWN" ;;
    6) MODE=5; ACTION_NAME="Move LEFT" ;;
    7) MODE=6; ACTION_NAME="Move RIGHT" ;;
    8) MODE=8; ACTION_NAME="Random Move" ;;
    *) MODE=0; ACTION_NAME="Left Click" ;;
esac

echo -n "Target total count ($ACTION_NAME): "
read TARGET_CLICKS
echo -n "Target Speed (Actions Per Second): "
read CPS

# Calculate delay in seconds (1/CPS)
DELAY=$(echo "scale=4; 1 / $CPS" | bc)

echo "------------------------------------------"
echo "!! WARNING: The mouse will $ACTION_NAME WHEREVER your cursor is !!"
echo "Move your mouse to a safe area now."
echo "Starting in 3... 2... 1..."
sleep 3

# Record start time
START_TIME=$(date +%s.%N)

# Check for Turbo Mode binary
TURBO_BIN="./script/mouse_turbo"
if [ ! -x "$TURBO_BIN" ]; then
    TURBO_BIN="./mouse_turbo" # Fallback
fi

# Always use Turbo for Scroll, or if Click speed > 50
USE_TURBO=0
if [ -x "$TURBO_BIN" ]; then
    if [ "$MODE" -ne 0 ] || [ "$CPS" -gt 50 ]; then
        USE_TURBO=1
    fi
fi

if [ "$USE_TURBO" -eq 1 ]; then
    echo "Turbo Mode Enabled! Using native injector."
    # Calculate delay in MICROseconds (1000000 / CPS / 2)
    TURBO_DELAY_US=$(echo "1000000 / ($CPS * 2)" | bc)
    
    # Run Turbo Injector with Mode
    "$TURBO_BIN" "$MODE" "$TARGET_CLICKS" "$TURBO_DELAY_US"
else
    # Standard Mode (ydotool) - Only supports clicking
    for ((i=1; i<=TARGET_CLICKS; i++)); do
        ydotool click 0xC0
        
        # Progress feedback
        if [ $((i % 10)) -eq 0 ] || [ $i -eq $TARGET_CLICKS ]; then
            printf "\rClicking: %d/%d" "$i" "$TARGET_CLICKS"
        fi
        
        sleep $DELAY
    done
fi

echo "" # Newline after progress

# Record end time
END_TIME=$(date +%s.%N)
TOTAL_TIME=$(echo "$END_TIME - $START_TIME" | bc)
ACTUAL_CPS=$(echo "scale=2; $TARGET_CLICKS / $TOTAL_TIME" | bc)

echo -e "\n\n------------------------------------------"
echo "TEST COMPLETE"
echo "Total Clicks: $TARGET_CLICKS"
echo "Total Time:   ${TOTAL_TIME}s"
echo "Actual CPS:   $ACTUAL_CPS"
echo "------------------------------------------"