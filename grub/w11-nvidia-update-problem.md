# KDE External Monitor Fix

Problem: External monitor works on the SDDM login screen but turns black/disappears from display settings immediately after logging into the KDE Wayland session. Happens often after driver or kernel updates.

Fix: Rebuild the initramfs images using Dracut to ensure the latest Nvidia DRM modesetting parameters are correctly baked into the boot stage:
```sh
sudo dracut --force --verbose
```

Reboot the system afterward:
```sh
sudo reboot
```