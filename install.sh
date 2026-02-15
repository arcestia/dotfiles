#!/bin/bash

DOTFILES=$HOME/dotfiles
CONFIG=$HOME/.config

echo "🔗 Creating symlinks for Fedora-Hyprland setup..."

# ZSH
ln -sf $DOTFILES/zsh/.zshrc $HOME/.zshrc
ln -sf $DOTFILES/zsh/.zprofile $HOME/.zprofile

# Git
ln -sf $DOTFILES/git/.gitconfig $HOME/.gitconfig
ln -sf $DOTFILES/git/.gitconfig-work $HOME/.gitconfig-work
ln -sf $DOTFILES/git/.gitconfig-skiddle $HOME/.gitconfig-skiddle
ln -sf $DOTFILES/git/.gitconfig-personal-gh $HOME/.gitconfig-personal-gh

# Config Folders (Hyprland ecosystem)
# We loop through your tracked configs to keep it clean
apps=( "hypr" "kitty" "waybar" "rofi" "wlogout" "swaync" "spicetify" "fastfetch" "wallust" )

for app in "${apps[@]}"; do
    if [ -d "$DOTFILES/config/$app" ]; then
        echo "Linking $app..."
        rm -rf "$CONFIG/$app" # Remove existing to prevent nested links
        ln -sf "$DOTFILES/config/$app" "$CONFIG/$app"
    fi
done

echo "✅ Setup complete! Reload Hyprland with Super+M or restart Zsh."
