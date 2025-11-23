# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository manages environment-specific dotfiles using Git branches. Each branch contains configuration files for a specific environment, and the main branch contains management scripts (`run.rb` and `targets.yaml`) for syncing dotfiles from the local system to the appropriate Git worktree based on automatic host identification.

## Branch Structure

- **main branch**: Contains management scripts for applying dotfile configurations
- **Environment branches**: Each branch contains dotfiles and configuration for a specific environment
  - `environments/macbook/2025`: macOS configuration (2025 version)
  - `environments/macbook/202410`: macOS configuration (October 2024 version)  
  - `win11-kaede-arch`: Windows 11 with Arch Linux subsystem configuration
  - `warabi`: Development/testing environment

## How It Works

### Automatic Host Identification
- Each host is identified by the MD5 hash of its hostname
- The `run.rb` script automatically detects the current host and finds matching configuration in `targets.yaml`
- Files are synced from the local system to the appropriate Git worktree directory

### Configuration Management
- `targets.yaml`: Defines host configurations, branch mappings, and target files
- Each host configuration specifies:
  - `md5`: MD5 hash of the hostname for identification
  - `branch`: Git branch containing the environment's dotfiles
  - `targets`: List of files/directories to sync

### Working with Environment Branches
- Each environment branch is self-contained with its own dotfiles
- Use `git worktree` to work with multiple environments concurrently
- Changes are synced from local system to worktree, then committed to the branch

## Common Commands

```bash
# Get your host's MD5 hash
ruby -e "require 'digest/md5'; puts Digest::MD5.hexdigest(\`hostname\`.strip)"

# List all available branches (including environment branches)
git branch -a

# Create a worktree for a specific environment
git worktree add environments/<environment-branch> <environment-branch>

# Sync local dotfiles to worktree (automatically detects host)
ruby run.rb

# List all worktrees
git worktree list

# Remove a worktree
git worktree remove environments/<environment-branch>
```

## Typical Workflow

1. **Initial Setup**:
   ```bash
   # Get your host's MD5 hash
   ruby -e "require 'digest/md5'; puts Digest::MD5.hexdigest(\`hostname\`.strip)"

   # Create environment branch (if needed)
   git checkout -b environments/macbook/2025
   git push -u origin environments/macbook/2025
   git checkout main

   # Create worktree
   git worktree add environments/macbook/2025 environments/macbook/2025

   # Add configuration to targets.yaml
   # (specify md5, branch, and target files)
   ```

2. **Sync Local Changes to Worktree**:
   ```bash
   # Automatically syncs based on hostname
   ruby run.rb
   ```

3. **Commit and Push Changes**:
   ```bash
   cd environments/macbook/2025
   git add .
   git commit -m "update dotfiles"
   git push
   cd ../..
   ```

4. **Deploy on Another Machine**:
   ```bash
   # On a machine with the same environment configuration
   git worktree add environments/macbook/2025 environments/macbook/2025
   cd environments/macbook/2025
   git pull
   # Manually copy files to home directory or use a deployment script
   ```

## targets.yaml Configuration

Example configuration structure:

```yaml
hosts:
  - md5: e7d8577877bbfda3608a3c2679e56a18
    branch: environments/macbook/2025
    targets:
      - target: "~/.tmux.conf"
        nukegara: "tmux.conf"
      - target: "~/.zshrc"
        nukegara: "zshrc"
      - target: "~/.config/nvim"
        nukegara: "config/nvim"
      - target: "~/.config/alacritty"
        nukegara: "config/alacritty"
```

- `md5`: MD5 hash of the hostname (run the command above to get it)
- `branch`: Git branch where this environment's dotfiles are stored
- `targets`: List of file/directory mappings
  - `target`: Path on the local system (supports `~` for home directory)
  - `nukegara`: Relative path within the worktree

## Development Notes

- This repository uses a branch-per-environment strategy
- Main branch contains shared tooling (`run.rb`, `targets.yaml`) and documentation
- Environment branches are isolated and environment-specific
- Use git worktree for concurrent work on multiple environments
- The sync is one-way: local system → worktree (does not automatically deploy to home directory)