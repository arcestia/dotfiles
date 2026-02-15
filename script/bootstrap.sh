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

  if [ -f "$dst" -o -d "$dst" -o -L "$dst" ]
  then
    # If the file exists and is already a link to the right place, skip it
    if [ $(readlink "$dst") == "$src" ]
    then
      skip=true
    else
      echo "File already exists: $dst, [s]kip, [o]verwrite, [b]ackup?"
      read -n 1 action
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

    ln -s "$src" "$dst"
    echo "  Linked $src to $dst"
  fi
}

# Find all *.symlink files and link them
# e.g., git/gitconfig.symlink -> ~/.gitconfig
for src in $(find -H "$DOTFILES_ROOT" -maxdepth 2 -name "*.symlink")
do
  dst="$HOME/.$(basename "${src%.*}")"
  link_file "$src" "$dst"
done

echo "✅ Bootstrap complete!"
