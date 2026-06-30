<div align="center">

# 🐍 nukegara

### Dotfiles that shed cleanly across every machine you own.

*Per-environment dotfile management powered by plain Git branches — no daemons, no symlink jungle, no magic.*

[![Ruby](https://img.shields.io/badge/Ruby-CC342D?logo=ruby&logoColor=white)](https://www.ruby-lang.org/)
[![Built with Thor](https://img.shields.io/badge/CLI-Thor-blueviolet)](https://github.com/rails/thor)
[![Powered by git worktree](https://img.shields.io/badge/git-worktree-F05032?logo=git&logoColor=white)](https://git-scm.com/docs/git-worktree)
![Zero dependencies beyond Ruby](https://img.shields.io/badge/dependencies-just_Ruby-success)

</div>

---

> **nukegara** (抜け殻) — *the empty shell a snake leaves behind when it sheds.*
> Each machine sheds its own configuration into its own branch, and `nukegara` keeps every shell in sync.

## ✨ Why nukegara?

Most dotfile managers ask you to bend your home directory around symlinks, bare repos, or a templating DSL. `nukegara` takes a different bet: **one Git branch per environment, one tiny Ruby script to move files between your filesystem and the right branch's worktree.** That's the whole idea.

- 🔍 **Zero-config host detection** — machines are identified by the MD5 hash of their hostname. Clone everywhere, run anywhere; the right config just follows.
- 🌿 **Branch = environment** — your MacBook, your Arch box, and your dev sandbox each live on their own branch. No cross-contamination.
- 🌲 **Built on `git worktree`** — every environment is checked out side by side. Edit, diff, and commit them all from one repo.
- 🎯 **Surgical sync** — only changed files move. `exclude` globs keep logs and junk out of version control.
- 🛟 **Dry-run by default** — every destructive command previews itself first. Add `--execute` only when you mean it.
- 🧬 **A shared `master/` layer** — promote a polished config to `master/` once, then fan it out to every environment that wants it.

## 🚀 Quickstart

```bash
# 1. Find this machine's fingerprint
ruby -e "require 'digest/md5'; puts Digest::MD5.hexdigest(\`uname -n\`.strip)"

# 2. Add the host + its target files to targets.yaml (see Configuration)

# 3. Create the worktree for this host's branch (creates & pushes the branch if needed)
ruby nukegara.rb git setup

# 4. Pull your current dotfiles into the worktree
ruby nukegara.rb local pull --execute
```

That's it. Your live dotfiles are now mirrored into a versioned Git branch.

## 🗂️ Layout

```
.
├── nukegara.rb         # the entire tool, in one Ruby file
├── targets.yaml        # hosts, branch mappings, file targets
├── master/             # optional: configs shared across environments
└── environments/       # git worktrees, one per branch
    └── macbook/2025/
```

## ⚙️ Configuration

Everything lives in `targets.yaml`. A host is matched by its hostname MD5, mapped to a branch, and given a list of files to track.

```yaml
master:
  path: master/                                # shared-config dir (optional)

hosts:
  - md5: e7d8577877bbfda3608a3c2679e56a18       # MD5 of `uname -n`
    branch: environments/macbook/2025           # the branch this host syncs to
    targets:
      - target: "~/.tmux.conf"                  # path on your filesystem
        nukegara: "tmux.conf"                   # path inside the worktree
      - target: "~/.zshrc"
        nukegara: "zshrc"
      - target: "~/.config/nvim"                # directories work too
        nukegara: "config/nvim"
        exclude:                                # glob-based skip list (optional)
          - "**/*.log"                          # ** crosses directories; * does not
      - target: "~/.config/alacritty"
        nukegara: "config/alacritty"
```

| Key                  | What it does                                                              |
| -------------------- | ------------------------------------------------------------------------- |
| `master.path`        | Directory holding configs shared across environments. Optional.           |
| `md5`                | MD5 hash of the hostname (`uname -n`), used to auto-pick the host.        |
| `branch`             | The Git branch storing this environment's dotfiles.                       |
| `targets[].target`   | Path on the local filesystem (`~` expands to `$HOME`).                    |
| `targets[].nukegara` | Matching relative path inside the worktree.                               |
| `targets[].exclude`  | `File.fnmatch` globs to skip. Applies to **every** command consistently.  |

## 🧭 Commands

`nukegara` groups its work into four subcommand families. Run `ruby nukegara.rb tree` any time to see the full map.

### 🩺 `health` — the one-line status check

```bash
ruby nukegara.rb health    # compact summary of diffs across local <-> env <-> master
```

### 💻 `local` — your filesystem ⇄ the env worktree

```bash
ruby nukegara.rb local diff             # what's different?
ruby nukegara.rb local pull             # filesystem -> worktree (dry-run)
ruby nukegara.rb local pull --execute   # filesystem -> worktree (for real)
ruby nukegara.rb local apply --execute  # worktree -> filesystem (deploy to a new machine)
```

### 🌐 `master` — the shared layer ⇄ the env worktree

```bash
ruby nukegara.rb master diff                       # master vs. this env (conflicts in red)
ruby nukegara.rb master apply --execute            # push master's version into the env
ruby nukegara.rb master promote                    # promote all conflicting env files (dry-run)
ruby nukegara.rb master promote --execute          # ...for real
ruby nukegara.rb master promote config/nvim/init.lua --execute   # promote one specific file
```

### 🔧 `git` — worktree git, without the `cd`

```bash
ruby nukegara.rb git status               # git status of the env worktree
ruby nukegara.rb git stage                # git add -A
ruby nukegara.rb git commit -m "..."      # commit staged changes (message optional)
ruby nukegara.rb git push                 # push the branch
ruby nukegara.rb git setup                # create the worktree (and branch) for this host
```

## 🔄 A day in the life

```bash
# You tweaked ~/.tmux.conf on your laptop. Capture it:
ruby nukegara.rb local diff               # eyeball the change
ruby nukegara.rb local pull --execute     # mirror it into the worktree

# Commit and push it from the branch:
ruby nukegara.rb git stage
ruby nukegara.rb git commit -m "tmux: bigger scrollback"
ruby nukegara.rb git push

# On another machine with the same environment branch:
ruby nukegara.rb git setup
git -C environments/macbook/2025 pull
ruby nukegara.rb local apply --execute    # roll the config onto disk
```

## 🧪 How host detection works

Each host hashes its own name with MD5 (`uname -n`). At startup `nukegara.rb` computes the local hash, finds the matching entry in `targets.yaml`, and operates only on that host's branch and targets. Move to a new machine, add its hash, and the same commands keep working — no flags, no environment variables.

---

<div align="center">
<sub>Built with Ruby + Thor + <code>git worktree</code>. One file, no daemons, no surprises.</sub>
</div>
