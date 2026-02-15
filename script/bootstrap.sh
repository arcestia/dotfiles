#!/bin/bash

DOTFILES_ROOT=$(pwd -P)

set -e

echo "🚀 Starting bootstrap..."

# Function to create symlinks
link_file () {
  local src=$1 dst=$2

  local overwrite=
  local backup=
  local skip=

  if [ -f "$dst" ] || [ -d "$dst" ] || [ -L "$dst" ]
  then
    # If it's already a link to the right place, skip it
    if [ "$(readlink "$dst")" == "$src" ]
    then
      skip=true
    else
      echo "File already exists: $dst, [s]kip, [o]verwrite, [b]ackup?"
      read -n 1 action
      echo "" # newline
      case "$action" in
        o ) overwrite=true;;
        b ) backup=true;;
        s ) skip=true;;
        * ) ;;
      esac
    fi
  fi

  if [ "$skip" == "true" ]
  then
    echo "  Skipping $src"
  else
    if [ "$overwrite" == "true" ]
    then
      rm -rf "$dst"
      echo "  Removed $dst"
    fi

    if [ "$backup" == "true" ]
    then
      mv "$dst" "${dst}.bak"
      echo "  Backed up $dst to ${dst}.bak"
    fi

    # Ensure the parent directory exists (critical for .config/ folders)
    mkdir -p "$(dirname "$dst")"
    
    ln -s "$src" "$dst"
    echo "  Linked $src to $dst"
  fi
}

# --- LOGIC ---

# 1. Handle standard .symlink files (Target: $HOME/.name)
# Example: git/gitconfig.symlink -> ~/.gitconfig
for src in $(find -H "$DOTFILES_ROOT" -maxdepth 2 -name "*.symlink")
do
  dst="$HOME/.$(basename "${src%.*}")"
  link_file "$src" "$dst"
done

# 2. Handle .config files (Target: $HOME/.config/name)
# We look for anything inside 'config' folders in your topics
# Example: hypr/config/hypr -> ~/.config/hypr
for src in $(find -H "$DOTFILES_ROOT" -maxdepth 3 -path "*/config/*")
do
  # Calculate relative path from the 'config' folder
  # This allows for nested configs like ~/.config/hypr/hyprland.conf
  rel_path=$(echo "$src" | sed 's|.*\/config\/||')
  dst="$HOME/.config/$rel_path"
  link_file "$src" "$dst"
done

echo "✅ Bootstrap complete!"
