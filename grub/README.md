# GRUB

## Black screen on first boot

On a fresh Fedora install, if you get no display after boot (e.g. dual GPU), press `e` in the GRUB menu and add `nomodeset` to the end of the `linux` line, then boot.

You can always get a TTY with **Ctrl+Alt+F3** (or F2–F6) and fix things from there.

## Theme

Based on [Particle GRUB theme](https://github.com/yeyushengfan258/Particle-grub-theme) (sidebar variant). The script in this folder is adapted for Fedora: it installs to `/boot/grub2/themes`, sets `GRUB_TERMINAL_OUTPUT=gfxterm` and `GRUB_ENABLE_BLSCFG=false`, then runs `grub2-mkconfig`.

**Usage:** From a directory that contains the `Particle-sidebar` folder (clone the theme repo and run its installer with `-t sidebar` once to generate it, or use a release), run:

```sh
sudo ./theme.sh
```

Reboot to apply.
