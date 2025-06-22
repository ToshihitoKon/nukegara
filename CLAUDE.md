# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Structure

This is a dotfiles repository where the git root corresponds to the home directory structure. Files are organized as they would appear in a user's home directory, but symbolic links are intentionally not used.

## Architecture Overview

### Multi-Window Manager Setup
The configuration supports three window managers:
- **XMonad** (primary) - Haskell-based tiling WM with custom xmonad.hs configuration
- **i3** - Lightweight tiling WM with autotiling
- **Sway** - Wayland compositor compatible with i3

### Key Configuration Files
- `.xmonad/xmonad.hs` - Main XMonad configuration with BSP/Tall/Grid layouts
- `.config/i3/config` - i3 window manager configuration
- `.config/sway/config` - Sway (Wayland) configuration
- `.vimrc` - Vim configuration with vim-plug and development plugins
- `.zshrc` - Zsh configuration with vi-mode and custom prompt
- `.tmux.conf` - tmux configuration with Ctrl+n prefix

### Custom Scripts Location
Custom automation scripts are located in `.config/nukegara_scripts/`:
- `ss.sh` - Screenshot utility with clipboard integration
- `battery.sh` - Battery monitoring with notifications
- `screenlock.sh` - Screen locking configuration
- `move_nukegara.sh` - Configuration file deployment script

### Application Configurations
- **Alacritty** (`.config/alacritty/`) - Primary terminal with transparency
- **Rofi** (`.config/rofi/`) - Application launcher
- **Dunst** (`.config/dunst/`) - Desktop notifications
- **Picom** (`.config/picom/`) - X11 compositor

### Input and Hardware Settings
Configurations are optimized for ThinkPad hardware:
- Trackpoint sensitivity adjustments in `.xinitrc` and `.xprofile`
- Touchpad disable settings
- Support for ELECOM trackball devices
- Japanese input via fcitx/fcitx5

### Development Environment
- Multi-language support (Go, Python, JavaScript)
- Git integration across all editors
- Code formatting with Prettier
- asdf-vm for version management (referenced in shell config)

### Branch Strategy
- Current branch: `warabi`
- Main branch: `master`
- Branches may represent different environment configurations

## Working with This Repository

### Synchronization Script
Use `sync_dotfiles.sh` to synchronize configuration files between the nukegara repository and home directory:

- `./sync_dotfiles.sh to-home` - Copy from nukegara to home directory
- `./sync_dotfiles.sh from-home` - Copy from home directory to nukegara
- Add `--force` to skip diff confirmation

**Target files:**
- Dotfiles in home directory (e.g., `.zshrc`, `.vimrc`, `.tmux.conf`)  
- Directories under `.config/` (copied with `cp -r`)

The script shows diffs before copying and asks for confirmation unless `--force` is used.

### X11/Wayland Support
The configuration provides both X11 and Wayland compatibility:
- X11: XMonad + i3 support
- Wayland: Sway configuration
- Session management via `.xinitrc` and `.xprofile`

### Japanese Environment
The setup includes Japanese localization:
- fcitx/fcitx5 input methods
- Japanese emoji in zsh prompt: `(*>△<)`
- Locale-aware applications

### Hardware Optimization
Settings are specifically tuned for:
- DPI scaling (75 DPI)
- Keyboard repeat rates
- Mouse acceleration settings
- Power management (battery monitoring)