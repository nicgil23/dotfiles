#!/bin/bash
# Ported from 'ii'
# NANDOROID Music Recognition Script
# Optimized to use native songrec recognition

INTERVAL=5
TOTAL_DURATION=30
SOURCE_TYPE="monitor"  # monitor | input

while getopts "i:t:s:" opt; do
  case $opt in
    i) INTERVAL=$OPTARG ;;
    t) TOTAL_DURATION=$OPTARG ;;
    s) SOURCE_TYPE=$OPTARG ;;
    *) exit 1 ;;
  esac
done

# Try to find the device string for songrec
# Note: songrec outputs its device list to stderr, so we must redirect it.
if [ "$SOURCE_TYPE" = "monitor" ]; then
    # Look for the default sink's monitor
    DEFAULT_SINK=$(pactl get-default-sink 2>/dev/null)
    # The grep pattern handles both pulseaudio: prefix and direct alsa: names
    # We look for Available device: and then the sink name
    DEVICE_STRING=$(songrec recognize -l 2>&1 | grep "Available device:" | grep "$DEFAULT_SINK" | head -n 1 | sed -n 's/.*Available device: \([^ ]*\).*/\1/p')
    
    # Fallback: just search for any monitor if specific one fails
    if [ -z "$DEVICE_STRING" ]; then
        DEVICE_STRING=$(songrec recognize -l 2>&1 | grep "Available device:" | grep ".monitor" | head -n 1 | sed -n 's/.*Available device: \([^ ]*\).*/\1/p')
    fi
else
    # Look for default input source
    DEFAULT_SOURCE=$(pactl get-default-source 2>/dev/null)
    DEVICE_STRING=$(songrec recognize -l 2>&1 | grep "Available device:" | grep "$DEFAULT_SOURCE" | head -n 1 | sed -n 's/.*Available device: \([^ ]*\).*/\1/p')
    
    # Fallback: search for any analog-stereo input
    if [ -z "$DEVICE_STRING" ]; then
        DEVICE_STRING=$(songrec recognize -l 2>&1 | grep "Available device:" | grep "input" | grep -v ".monitor" | head -n 1 | sed -n 's/.*Available device: \([^ ]*\).*/\1/p')
    fi
fi

if ! command -v songrec >/dev/null 2>&1; then
    exit 1
fi

# Run songrec directly. -j for JSON, -i for interval.
# We use timeout command to limit the duration.
# We also use 'grep --line-buffered' to ensure we only output valid JSON lines
if [ -n "$DEVICE_STRING" ]; then
    timeout "$TOTAL_DURATION" songrec recognize -j -d "$DEVICE_STRING" -i "$INTERVAL" | grep --line-buffered "^{"
else
    # Last resort: just use default mic
    timeout "$TOTAL_DURATION" songrec recognize -j -i "$INTERVAL" | grep --line-buffered "^{"
fi
