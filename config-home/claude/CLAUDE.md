# Global Claude Code Settings

## Git Commit Signatures

**IMPORTANT**: NEVER add "Co-Authored-By: Claude" to any git commit messages. Only use the author's git signature (rishitv).

When creating git commits:
- Do NOT include any co-author lines for Claude
- Do NOT include "> Generated with [Claude Code](https://claude.com/claude-code)" unless explicitly requested
- Use ONLY the user's git signature configured in git config

Example commit message format:
```
<type>: <subject>

<body>
```

## Code Style Preferences

- Prefer functional programming patterns where appropriate
- Use TypeScript strict mode when working with TS
- Follow existing project conventions before suggesting changes
- Keep functions small and focused
- Avoid over-engineering; keep solutions simple

## Tools & Environment

- **Shell**: zsh with Ghostty terminal + Zellij multiplexer
- **Primary languages**: Python, TypeScript, Go
- **Package managers**: npm/bun for JS, pip/uv for Python, go mod for Go
- **Container runtime**: Colima (Docker-compatible)
- **Version managers**: nvm (Node), jenv (Java)

### Modern CLI Tools Available
- `eza` - Modern ls with icons (aliases: ls, ll, lt, la)
- `bat` - Cat with syntax highlighting (aliases: cat, catp)
- `fd` - Fast find (alias: find)
- `zoxide` - Smart cd (command: z)
- `ripgrep` - Fast grep (command: rg)
- `fzf` - Fuzzy finder (Ctrl+T files, Alt+C dirs, Ctrl+R history)
- `atuin` - Shell history with sync
- `yazi` - TUI file manager (command: y)

## Workflow Preferences

- Run tests after making changes when test suite exists
- Prefer editing existing files over creating new ones
- Use conventional commits format (feat:, fix:, chore:, etc.)
- Check for linting issues before committing
- Use ruff for Python linting/formatting

## Project Patterns

- Infrastructure code uses Terraform/Terragrunt
- Kubernetes deployments use Helm
- Always check .env.example for required environment variables
- Python projects typically use pyproject.toml

## Secrets Management

- Use 1Password CLI (`op`) for secrets
- `withenv <command>` - Run command with secrets from 1Password
- Never hardcode secrets in files
- Check `OP_VARS` in .zshrc for available secret mappings
