# nukegara - Environment-Specific Dotfiles Management

A Git-based dotfiles management system that uses branches for environment-specific configurations and MD5-based host identification for automatic deployment.

## Overview

`nukegara` manages dotfiles across multiple environments using Git branches. Each environment has its own branch containing configuration files, and the main branch contains management scripts that automatically sync configurations based on the host machine.

## Features

- **Automatic host identification**: Uses MD5 hash of hostname to identify machines
- **Branch-based environments**: Each environment lives in its own Git branch
- **Git worktree integration**: Uses Git worktrees for concurrent environment management
- **Smart file syncing**: Only copies files that have changed
- **Directory support**: Can sync both individual files and entire directories

## How It Works

1. Each host is identified by the MD5 hash of its hostname
2. Configuration for each host is defined in `targets.yaml`
3. The script syncs files from the local system to the appropriate Git worktree directory
4. Changes can be committed and pushed to the environment-specific branch

## Repository Structure

```
.
├── run.rb              # Main sync script
├── targets.yaml        # Host configurations and target files
└── <branch-name>/      # Git worktrees (not tracked)
```

## Configuration

### targets.yaml

Define your hosts and target files in `targets.yaml`:

```yaml
hosts:
  - md5: e7d8577877bbfda3608a3c2679e56a18  # MD5 hash of hostname
    branch: environments/macbook/2025        # Git branch for this environment
    targets:
      - target: "~/.tmux.conf"              # Source file on local system
        nukegara: "tmux.conf"               # Destination in worktree
      - target: "~/.config/nvim"            # Can also be a directory
        nukegara: "config/nvim"
```

### Getting Your Host's MD5

To find your host's MD5 hash:

```bash
ruby -e "require 'digest/md5'; puts Digest::MD5.hexdigest(\`hostname\`.strip)"
```

## Setup

1. **Create environment branch**:

```bash
git checkout -b environments/macbook/2025
git push -u origin environments/macbook/2025
git checkout main
```

2. **Create worktree**:

```bash
git worktree add environments/macbook/2025 environments/macbook/2025
```

3. **Configure targets.yaml**:

- Add your host's MD5 hash
- Specify the branch name
- List files/directories to sync

4. **Run sync**:

```bash
ruby run.rb
```

## Usage

### Sync files to worktree

```bash
ruby run.rb
```

This will:
1. Identify your host by MD5 hash
2. Find matching configuration in `targets.yaml`
3. Copy specified files/directories to the worktree
4. Skip files that haven't changed

### Commit and push changes

```bash
cd environments/macbook/2025
git add .
git commit -m "Update dotfiles"
git push
```

## Example Workflow

1. Make changes to your local dotfiles (e.g., edit `~/.tmux.conf`)
2. Run `ruby run.rb` to sync changes to the worktree
3. Review changes in the worktree directory
4. Commit and push to the environment branch
5. On another machine with the same environment, pull the changes and deploy
