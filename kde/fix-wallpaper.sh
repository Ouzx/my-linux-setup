#!/bin/bash

# I'm using wallpaper engine on plasma, but it's causing the system to crash on some wallpapers.
# This script will comment out the Wallpaper Engine plugin line in the Plasma config to revert to the default wallpaper.

# Path to the Plasma config
CONFIG_FILE="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"

# 1. Create a backup just in case
cp "$CONFIG_FILE" "$CONFIG_FILE.bak"

# 2. Use sed to comment out the Wallpaper Engine plugin line
# This looks for the specific plugin string and adds a '#' to the start of the line
sed -i 's/^wallpaperplugin=com.github.catsout.wallpaperEngineKde/#&/' "$CONFIG_FILE"

echo "Wallpaper Engine line commented out in config."

# 3. Restart Plasma using your preferred method
echo "Restarting Plasma..."
systemd-run --user plasmashell --replace

echo "Done. Plasma should now revert to the default wallpaper."
