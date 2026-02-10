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

# Fix Wallpaper Engine crash (adjust path to where you keep fix-wallpaper.sh)
alias fix-wp='~/Projects/my-linux-setup/kde/fix-wallpaper.sh'