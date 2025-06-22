# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository manages environment-specific dotfiles using Git branches. Each branch contains configuration files for a specific environment, and the main branch contains management scripts for applying these configurations to local systems.

## Branch Structure

- **main branch**: Contains management scripts for applying dotfile configurations
- **Environment branches**: Each branch contains dotfiles and configuration for a specific environment
  - `environments/macbook/2025`: macOS configuration (2025 version)
  - `environments/macbook/202410`: macOS configuration (October 2024 version)  
  - `win11-kaede-arch`: Windows 11 with Arch Linux subsystem configuration
  - `warabi`: Development/testing environment

## Basic Workflow

### Applying Configurations
1. Use `git worktree` to checkout the desired environment branch
2. Specify the worktree directory when running the management script
3. Execute the script to apply the configuration to the local environment

### Working with Environment Branches
- Each environment branch is self-contained with its own dotfiles
- Switch between branches using `git worktree` rather than direct checkout
- Management scripts from main branch handle the application process

## Common Commands

```bash
# List all available branches (including environment branches)
git branch -a

# Create a worktree for a specific environment
git worktree add <worktree-path> <environment-branch>

# Apply configuration from worktree to home directory
./sync_dotfiles.sh <worktree-path> to-home

# Copy current home configuration to worktree
./sync_dotfiles.sh <worktree-path> from-home

# Force copy without confirmation
./sync_dotfiles.sh <worktree-path> to-home --force
```

## Typical Workflow

1. **Setup Environment Worktree**:
   ```bash
   git worktree add ./env-macbook environments/macbook/2025
   ```

2. **Apply Configuration**:
   ```bash
   ./sync_dotfiles.sh ./env-macbook to-home
   ```

3. **Save Changes Back to Repository**:
   ```bash
   ./sync_dotfiles.sh ./env-macbook from-home
   cd ./env-macbook && git add . && git commit -m "update dotfiles"
   ```

## Development Notes

- This repository uses a branch-per-environment strategy
- Main branch contains shared tooling and scripts
- Environment branches are isolated and environment-specific
- Use git worktree for concurrent work on multiple environments