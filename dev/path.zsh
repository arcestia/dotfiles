# Deno Setup
export PATH="$HOME/.deno/bin:$PATH"
[ -s "$HOME/.deno/env" ] && . "$HOME/.deno/env"

# NVM Setup
export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Spicetify & Local Bin
export PATH="$PATH:$HOME/.spicetify:$HOME/.local/bin"
