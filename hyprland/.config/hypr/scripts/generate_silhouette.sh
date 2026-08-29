#!/bin/bash
# Script to generate a silhouette from a wallpaper using rembg

WALLPAPER="$1"
OUTPUT="$HOME/.cache/silhouette.png"

# We must ensure rembg is installed
if ! command -v rembg &> /dev/null; then
    echo "rembg is not installed. Silhouette generation skipped."
    # We clear the output file so hyprlock doesn't show the old silhouette
    rm -f "$OUTPUT"
    exit 0
fi

if [ ! -f "$WALLPAPER" ]; then
    echo "Wallpaper file not found: $WALLPAPER"
    rm -f "$OUTPUT"
    exit 0
fi

echo "Generating silhouette for $WALLPAPER..."
# Run rembg to remove background
rembg i "$WALLPAPER" "$OUTPUT"

echo "Silhouette generation complete!"
