# Place under: /etc/profile.d/kwin_nvidia_fix.sh
# Dual GPU (Nvidia Optimus). By default KWin uses the integrated GPU, which is not optimal for external monitors.
# Create this script and reboot.

export KWIN_DRM_DEVICES=/dev/dri/card0:/dev/dri/card1
export KWIN_TRIPLE_BUFFER=1