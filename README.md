# nukegara - Environment-Specific Dotfiles Management

nukegara is a dotfiles management system that uses Git branches to organize configurations for different environments. Each branch contains dotfiles and configuration files specific to a particular environment (e.g., macOS, Linux, Windows).

## Overview

This repository structure allows you to:
- Manage multiple environment configurations in a single repository
- Use Git worktrees to work with different environments simultaneously
- Synchronize dotfiles between your local system and the repository
- Track changes to configurations over time

## Repository Structure

```
nukegara/
├── sync_dotfiles.sh      # Main synchronization script
├── CLAUDE.md            # Claude Code instructions
└── README.md            # This file
```

## Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url> nukegara
cd nukegara
```

### 2. Create a Worktree for Your Environment

```bash
# Create a worktree for macOS 2025 environment
git worktree add ./env-macbook environments/macbook/2025

# Or for Windows environment
git worktree add ./env-windows win11-kaede-arch
```

### 3. Apply Configuration to Your System

```bash
# Review differences and apply configuration
./sync_dotfiles.sh ./env-macbook to-home

# Or apply without confirmation
./sync_dotfiles.sh ./env-macbook to-home --force
```

### 4. Save Local Changes Back to Repository

```bash
# Copy current system configuration to repository
./sync_dotfiles.sh ./env-macbook from-home

# Commit changes
cd ./env-macbook
git add .
git commit -m "update dotfiles configuration"
git push
```

## Detailed Usage

### Working with Worktrees

Git worktrees allow you to have multiple branches checked out simultaneously:

```bash
# List existing worktrees
git worktree list

# Add a new worktree
git worktree add <path> <branch>

# Remove a worktree
git worktree remove <path>
```

### Synchronization Script

The `sync_dotfiles.sh` script handles copying files between your system and the repository:

```bash
./sync_dotfiles.sh <worktree-path> <direction> [--force]
```

**Arguments:**
- `<worktree-path>`: Path to the worktree directory
- `<direction>`: Either `to-home` or `from-home`
- `--force`: Skip diff confirmation (optional)

**Supported Files:**
- Dotfiles in home directory (`.zshrc`, `.vimrc`, `.tmux.conf`, etc.)
- Configuration directories under `.config/` (`.config/alacritty`, `.config/nvim`, etc.)

### Examples

#### Setting up a new environment:
```bash
# Create worktree for new environment
git worktree add ./my-laptop environments/macbook/2025

# Apply existing configuration
./sync_dotfiles.sh ./my-laptop to-home
```

#### Updating configuration:
```bash
# Make changes to your dotfiles locally
# Then save changes back to repository
./sync_dotfiles.sh ./my-laptop from-home

# Commit and push changes
cd ./my-laptop
git add .
git commit -m "feat: add new zsh aliases"
git push
```

#### Switching between environments:
```bash
# Setup multiple environments
git worktree add ./work-mac environments/macbook/2025
git worktree add ./personal-linux environments/linux/desktop

# Switch to work environment
./sync_dotfiles.sh ./work-mac to-home

# Later, switch to personal environment
./sync_dotfiles.sh ./personal-linux to-home
```

## Available Environments

- **environments/macbook/2025**: Latest macOS configuration
- **environments/macbook/202410**: macOS configuration from October 2024
- **win11-kaede-arch**: Windows 11 with Arch Linux subsystem
- **warabi**: Development/testing environment

## Best Practices

1. **Always review changes**: Use the script without `--force` to see what will be changed
2. **Commit regularly**: Save your configuration changes frequently
3. **Use descriptive commit messages**: Follow conventional commit format
4. **Test configurations**: Use the development branch for testing new configurations
5. **Backup important files**: Keep backups of critical configuration files

## Troubleshooting

### Common Issues

**Worktree path doesn't exist:**
```bash
# Make sure the worktree was created properly
git worktree list
```

**Permission denied:**
```bash
# Make sure the script is executable
chmod +x sync_dotfiles.sh
```

**Files not being detected:**
The script looks for:
- Dotfiles starting with `.` in the worktree root
- Directories under `.config/` in the worktree

### Getting Help

```bash
# Show script usage
./sync_dotfiles.sh

# List available branches
git branch -a

# Check worktree status
git worktree list
```

## Contributing

1. Create a new branch for your environment
2. Add your dotfiles and configurations
3. Test the synchronization script
4. Submit a pull request with your changes

## License

This project is for personal dotfiles management. Please respect the licenses of any included configuration files or scripts.
