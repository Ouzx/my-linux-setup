# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="agnoster"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting fast-syntax-highlighting zsh-autocomplete)

source $ZSH/oh-my-zsh.sh

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
# bun completions
[ -s "/home/ouzx/.bun/_bun" ] && source "/home/ouzx/.bun/_bun"

# cat => bat
alias catt='bat'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# cursor
alias cursor='gtk-launch cursor'

# restart plasma completely
alias rsp='systemd-run --user plasmashell --replace'

# chrome flatpak
alias google-chrome="flatpak run com.google.Chrome"

# updates all packages
alias upup='sudo dnf upgrade -y && flatpak update -y && cvm --update'

# Obsidian Sync
alias gsync="(cd ~/Oz/ozxk-vault/ && git add . && git commit -m 'update' && git push)"

# Fedora usb file transfer fix; reduce mem cache size, then reset it when you done.
# Toggle USB-friendly low write-cache mode
usbcache-low() {
    echo "--- Restricting system write cache for slow USB drives ---"
    sudo sysctl -w vm.dirty_bytes=15728640
    sudo sysctl -w vm.dirty_background_bytes=15728640
    echo "Done. Progress bars will now reflect physical device speeds."
}

# Revert to Fedora's high-performance defaults
usbcache-default() {
    echo "--- Restricting cache by bytes deactivated ---"
    sudo sysctl -w vm.dirty_bytes=0
    sudo sysctl -w vm.dirty_background_bytes=0
    echo "--- Re-enabling Fedora default percentages ---"
    sudo sysctl -w vm.dirty_ratio=40
    sudo sysctl -w vm.dirty_background_ratio=10
    echo "Done. High-performance RAM buffering restored."
}

alias usb-use="usbcache-low"
alias usb-unuse="usbcache-default"