<!-- This file is maintained by Claude. Edit via Claude so the structure stays consistent. -->

# Global Rules

## macOS: installing software

- **Never use Homebrew.** Do not run `brew` or suggest it as an option.
- **For one-off or short-lived commands, use a Docker image** (`docker run --rm ...`) instead of installing anything.
- **For tools that need a persistent install, download a prebuilt binary**, preferably from the project's official GitHub Releases.
  - **Before downloading, confirm the source with the user**: give the exact URL and the repository/owner, and wait for approval.
  - Install it into a versioned directory: `~/.local/share/<name>-<version>/`
  - Symlink the executable into `~/.local/bin/`, for example `ln -s ~/.local/share/<name>-<version>/<name> ~/.local/bin/<name>`.
  - To upgrade, install the new version alongside the old one and repoint the symlink.
