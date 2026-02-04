# Claude Code Settings

User-level Claude Code configuration files for syncing across devices.

## Contents

- `CLAUDE.md` - Global instructions for Claude Code
- `settings.json` - Settings (API key removed - add your own)
- `agents/` - Custom agents
- `skills/` - Custom skills

## Recovery

To restore these configs to a new machine:

```bash
# Clone the repo and checkout claude branch
git clone https://github.com/specbug/iconfig.git
cd iconfig
git checkout claude

# Copy to ~/.claude (create backup first if exists)
cp -r config-home/claude/* ~/.claude/

# Add your API key to settings.json
# Either edit ~/.claude/settings.json or use ANTHROPIC_API_KEY env var
```

## Plugins to Install

After recovery, install these plugins:

```bash
# From claude-code-plugins marketplace
claude plugin install pr-review-toolkit
claude plugin install agent-sdk-dev
claude plugin install commit-commands

# From claude-plugins-official marketplace
claude plugin install ralph-loop
```

## Notes

- `settings.json` has `apiKeyHelper` removed for security - configure your API key separately
- Plugin caches are NOT synced - plugins will auto-download when installed
- The `settings.local.json` is device-specific and not synced
