## Better Blur DX

Getting window blur in KDE + Wayland is hard. Many plugins are outdated or unmaintained on Plasma 6 + Fedora 43.

There are many forks of the same repo; I tried several and only this one worked reliably:
https://github.com/xarblu/kwin-effects-better-blur-dx

Disable *blur* effect first.

**General**
My config is:
Blur: 50%
Noise: 100%
Brightness/Saturation/Contrast: 24

**Force Blur**
Class names can differ between X11 and Wayland sessions. There were no X11 packages in a fresh Fedora 43 setup—I had to install manually and tweak GPU boot settings. Wayland is the better option.

classes:
```
cursor
dev.warp.Warp
dev.zed.Zed
code
```
Blur only matching
Blur window decorations as well
Blur menus
Blur docks

**Install**
Check the official docs first.
```sh
dnf copr enable infinality/kwin-effects-better-blur-dx
dnf install kwin-effects-better-blur-dx
# dnf install kwin-effects-better-blur-dx-x11
```

---
## Others
- Translucency
- Wobbly Windows
- Cuber
- Overview

These are also enabled.