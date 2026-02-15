# Icons and listing using lsd
alias ls='lsd'
alias l='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'
alias ds='dotsync'

# Appearance Logic
# If pokemon-colorscripts is installed, use it with fastfetch
if command -v pokemon-colorscripts > /dev/null; then
    pokemon-colorscripts --no-title -s -r | fastfetch -c $HOME/.config/fastfetch/config-pokemon.jsonc --logo-type file-raw --logo-height 10 --logo-width 5 --logo -
else
    fastfetch -c $HOME/.config/fastfetch/config-compact.jsonc
fi
