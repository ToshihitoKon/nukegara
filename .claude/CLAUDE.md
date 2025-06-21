# Communication Language
- Conduct all conversations in Japanese
- Always write CLAUDE.md instructions in English to ensure Claude can accurately understand the context

# Documentation Guidelines
- For new documentation files:
  - Create README.md in English
  - Create README-ja.md in Japanese
- For existing documentation files:
  - Follow the language already used in the file

# Available Tools
- Use the `tree` command to understand directory structure

# Git Commit Guidelines
- Follow Conventional Commits specification when creating commits
  - Format: `<type>[optional scope]: <description>`
  - Types: feat, fix, docs, style, refactor, test, chore, perf, ci, build, revert
  - Breaking changes: add `!` after type/scope or add `BREAKING CHANGE:` in footer
  - Examples:
    - `feat: add user authentication`
    - `fix(auth): resolve login timeout issue`
    - `feat!: remove deprecated API endpoints`

# Pull Request Creation
- When creating PRs using `gh`:
  - Follow the title format: `[stage(optional)]: [type] [oneline description]`
    - stage: dev-staging, production, internal etc. (target environment)
    - type: fix, cleanup, feat, chore etc. (type of PR content)
    - oneline description: brief one-line description of changes
    - Example: `dev-staging: fix: typo default tag key STASE to STAGE`
  - Write the description in English
  - Add Claude Code context information in a `<details>` tag with summary "claude code context"
  - Use relative paths from project root when including file paths
  - Apply any available repository labels that indicate the PR was created by Claude
