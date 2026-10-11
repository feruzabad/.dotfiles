<!-- This file is maintained by Claude. Edit via Claude so the structure stays consistent. -->

# Global Rules

## Editing this file

- **When the user asks to add something to CLAUDE.md, never paste their wording verbatim.** Proofread it, resolve ambiguity, and rewrite it as clear, direct instructions optimized for Claude's understanding.
- Fit new rules into the existing structure (merge with related rules, avoid duplicates), and keep the maintenance note at the top.

## macOS: installing software

- **Never use Homebrew.** Do not run `brew` or suggest it as an option.
- **For one-off or short-lived commands, use a Docker image** (`docker run --rm ...`) instead of installing anything.
- **For tools that need a persistent install, download a prebuilt binary**, preferably from the project's official GitHub Releases.
  - **Before downloading, confirm the source with the user**: give the exact URL and the repository/owner, and wait for approval.
  - Install it into a versioned directory: `~/.local/share/<name>-<version>/`
  - Symlink the executable into `~/.local/bin/`, for example `ln -s ~/.local/share/<name>-<version>/<name> ~/.local/bin/<name>`.
  - To upgrade, install the new version alongside the old one and repoint the symlink.

## macOS: compiling from source

Only build from source when no suitable prebuilt binary exists.

- **Confirm the source with the user first** (exact URL of the tarball or repository), same as for binary downloads.
- **Prefer Docker images for the build toolchain** (e.g. `golang`, `rust`, `node`, `gcc` images) so compilers and build dependencies are not installed on the host. Mount the source directory and write the build output to a mounted directory.
  - **Caveat:** Docker on macOS runs Linux containers, which produce Linux binaries. Use Docker builds only when the output runs on macOS anyway: when the toolchain can cross-compile for `darwin` (e.g. Go with `GOOS=darwin GOARCH=arm64`), or when the output is platform-independent (scripts, JARs, web assets).
  - When a native macOS build is required, use the host toolchain (Xcode Command Line Tools). If a language toolchain is missing, install it as a versioned binary per the rules above, not via Homebrew.
- Keep source and build files in a temporary directory, not in `$HOME` or the dotfiles repository.
- Install the result into `~/.local/share/<name>-<version>/` (e.g. `./configure --prefix="$HOME/.local/share/<name>-<version>"`) and symlink it into `~/.local/bin/` as above.
