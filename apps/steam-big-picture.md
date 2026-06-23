```sh
cat <<EOF > ~/.local/share/applications/steam-big-picture.desktop
[Desktop Entry]
Name=Steam Big Picture
Comment=Launch Steam in Big Picture Mode
Exec=steam steam://open/bigpicture
Icon=steam
Terminal=false
Type=Application
Categories=Game;
EOF```

Run this command, and create a shortcut in the settings; I used `meta+g` for the shortcut.