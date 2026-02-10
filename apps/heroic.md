# Heroic Games Launcher

Personal backup of global settings. These apply as defaults for **new** installs; change existing games via the Settings button on each game page.

## Environment variables (ADVANCED tab)

For Nvidia Prime / discrete GPU (e.g. laptop with RTX):

```
__NV_PRIME_RENDER_OFFLOAD=1
__GLX_VENDOR_LIBRARY_NAME=nvidia
__VK_LAYER_NV_optimus=NVIDIA_only
DXVK_FILTER_DEVICE_NAME=4090
```

Add these in **Global Settings → ADVANCED → Environment Variables**. `DXVK_FILTER_DEVICE_NAME=4090` pins DXVK to the 4090; adjust the number if your GPU is different.

## WINE tab

- **Wine Version:** GE-Proton-latest
- **WinePrefix folder:** `~/Games/Heroic/Prefixes/default`
- **Enabled:** Auto Install/Update DXVK-NVAPI on Prefix, Esync, Fsync, Wine-Wayland (Experimental)
- **Disabled:** HDR, WoW64, FSR Hack

## OTHER tab

- **Enabled:** Show FPS (DX9/10/11), Mangohud, GameMode, Steam Runtime, BattlEye AntiCheat Runtime, EasyAntiCheat Runtime

(Mangohud and Feral GameMode must be installed on the system.)

## ADVANCED tab

- **Enable verbose logs:** on
- Environment variables: see above.
