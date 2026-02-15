# 🌌 Skiddle Dotfiles (Fedora + Hyprland)

Personal dotfiles managed and backed up to GitHub. This repository contains my workflow configurations for a Fedora-based Hyprland desktop environment, optimized for development across personal and work projects.

## 💻 Tech Stack
* **OS:** Fedora Linux
* **WM:** [Hyprland](https://hyprland.org/) (Wayland)
* **Shell:** Zsh (with Oh My Zsh)
* **Terminals:** Kitty (Primary), Ghostty, Wezterm
* **Editor:** Neovim / VS Code
* **Git Server:** Self-hosted [Forgejo](https://forgejo.org/) (git.skiddle.dev)

## 📁 Repository Structure
* `/config`: Most app-specific settings (Hyprland, Waybar, Rofi, etc.)
* `/git`: Multi-identity Git configurations (Work, Personal GH, Forgejo)
* `/zsh`: Shell aliases, profiles, and environment variables
* `install.sh`: Automated symlink script to deploy configurations

## 🚀 Quick Setup
To deploy these dotfiles on a fresh Fedora installation:

1. **Clone the repository:**
   ```bash
   git clone [https://github.com/arcestia/dotfiles.git](https://github.com/arcestia/dotfiles.git) ~/dotfiles
   cd ~/dotfiles
