# dotfiles

Personal agent instructions, skills, and CLI configuration.

## Installation

```sh
git clone git@github.com:feruzabad/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
stow --no-folding agents claude npm opencode skills
```

Requires [GNU Stow](https://www.gnu.org/software/stow/). `--no-folding` keeps shared directories such as `~/.agents` and `~/.claude` as real directories.

## Supported agents

| Agent | Instructions | Skills |
| --- | --- | --- |
| [Claude Code](https://code.claude.com) | `~/.claude/CLAUDE.md` | `~/.claude/skills/` |
| [OpenCode](https://opencode.ai) | `~/.config/opencode/AGENTS.md` | `~/.agents/skills/` |

The deployed paths are symlinks. Edit the canonical files under `agents/` and `skills/` in this repo.

## Skills

| Skill | Description |
| --- | --- |
| `macos-install` | Installs and upgrades macOS software without Homebrew, using Docker for one-offs and versioned installs under `~/.local/share`. |
