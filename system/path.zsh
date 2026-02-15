# Add the main dotfiles bin to PATH
export PATH="$HOME/dotfiles/bin:$PATH"

# Add topical bins only if they exist, without throwing an error
for bin_dir ($HOME/dotfiles/*/bin(N)) {
    export PATH="$bin_dir:$PATH"
}
