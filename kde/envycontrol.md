I have a dual-GPU setup (Nvidia + Intel). On KDE you need a tool to manage them; I use `envycontrol`.

https://github.com/bayasdev/envycontrol

This switches to Nvidia as the main GPU (you also need KWin to use Nvidia—see `kwin_nvidia_fix.sh`).

```sh
sudo envycontrol -s nvidia --dm sddm --force-comp --coolbits 28
```