#!/bin/bash

echo "================================"
echo "Installing Dotfiles"
echo "================================"

# Check for AUR helper
if ! command -v yay &> /dev/null && ! command -v paru &> /dev/null; then
    echo "Installing yay (AUR helper)..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay && makepkg -si --noconfirm
    cd -
fi

AUR_HELPER=$(command -v yay || command -v paru)

# Backup existing configs
BACKUP_DIR=~/dotfiles_backup_$(date +%Y%m%d_%H%M%S)
echo "Backing up existing configs to $BACKUP_DIR"
mkdir -p $BACKUP_DIR
[ -d ~/.config ] && cp -r ~/.config $BACKUP_DIR/
[ -d ~/.cache ] && cp -r ~/.cache $BACKUP_DIR/
[ -d ~/.local ] && cp -r ~/.local $BACKUP_DIR/
[ -f ~/.Xresources ] && cp ~/.Xresources $BACKUP_DIR/

# Install system packages
echo "Installing system packages..."
sudo pacman -S --needed --noconfirm \
    i3-wm polybar alacritty pcmanfm rofi picom feh scrot xclip \
    brightnessctl firefox-esr xsettingsd base-devel git \
    python python-pip python-pipx fish

# Install AUR packages
echo "Installing AUR packages..."
$AUR_HELPER -S --needed --noconfirm eww

# Set fish as default shell
echo "Setting fish as default shell..."
chsh -s $(which fish)

# Install Python packages via pipx
echo "Installing Python packages..."
pipx ensurepath
pipx install pywal
pipx install wpgtk

# Run wpgtk setup
echo "Setting up wpgtk..."
wpg-install.sh
wpg-install.sh -i

# Copy dotfiles
echo "Copying dotfiles..."
cp -r .config ~/
cp -r .cache ~/
cp -r .local ~/
cp .Xresources ~/

# Make scripts executable
echo "Setting permissions..."
chmod +x ~/.config/i3/autostart.sh
chmod +x ~/.config/polybar/launch.sh
chmod +x ~/.config/Scripts/*
find ~/.config/rofi -type f -name "*.sh" -exec chmod +x {} \;

# Merge Xresources
xrdb -merge ~/.Xresources

echo "================================"
echo "Installation Complete!"
echo "Backup saved at: $BACKUP_DIR"
echo ""
echo "NEXT STEPS:"
echo "1. Logout and login to i3"
echo "2. Fish shell will be active on next login"
echo "================================"
