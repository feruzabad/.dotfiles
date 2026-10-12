---
name: macos-install
description: Use BEFORE installing, upgrading, or compiling any software or CLI tool on macOS — prebuilt binaries, GitHub Releases, global npm packages, or building from source. Covers the Docker-first rule for one-off commands, versioned installs under ~/.local/share with symlinks in ~/.local/bin, source confirmation, and keeping ~/.local/share/install.log up to date. Never use Homebrew.
---

# Installing and building software on macOS

## Installing software

- **Never use Homebrew.** Do not run `brew` or suggest it as an option.
- **For one-off or short-lived commands, use a Docker image** (`docker run --rm ...`) instead of installing anything.
- **For tools that need a persistent install, download a prebuilt binary**, preferably from the project's official GitHub Releases.
  - **Before downloading, confirm the source with the user**: give the exact URL and the repository/owner, and wait for approval.
  - Install it into a versioned directory: `~/.local/share/<name>-<version>/`
  - Symlink the executable into `~/.local/bin/`, for example `ln -s ~/.local/share/<name>-<version>/<name> ~/.local/bin/<name>`.
  - To upgrade, install the new version alongside the old one and repoint the symlink.
- **Global npm packages are an exception:** install them with `npm install -g <pkg>`. `~/.npmrc` (tracked in the dotfiles `npm` stow package) sets `prefix=${HOME}/.local`, so packages go to `~/.local/lib/node_modules/` and commands land directly in `~/.local/bin/`. Do not create symlinks for them manually, and do not install into the versioned Node directory.
  - Packages with native modules (e.g. `keytar`, `node-pty`) need their install scripts allowed explicitly: `npm install -g --allow-scripts=<pkg1>,<pkg2> <package>`.
  - After a major Node upgrade, run `npm rebuild -g` so native modules match the new Node ABI.

## Install log

Keep `~/.local/share/install.log` up to date. It records how each program on PATH was installed (method, source URL, install path, symlinks, upgrade steps).

- **Before upgrading a program, read its latest entry** and upgrade the same way it was installed. If it has no entry, inspect how it was installed before changing anything.
- **After every install or upgrade, append a new dated entry** in the same format as the existing ones. Do not edit old entries.
- The log is machine-specific, so it is not tracked in the dotfiles.

## Compiling from source

Only build from source when no suitable prebuilt binary exists.

- **Confirm the source with the user first** (exact URL of the tarball or repository), same as for binary downloads.
- **Prefer Docker images for the build toolchain** (e.g. `golang`, `rust`, `node`, `gcc` images) so compilers and build dependencies are not installed on the host. Mount the source directory and write the build output to a mounted directory.
  - **Caveat:** Docker on macOS runs Linux containers, which produce Linux binaries. Use Docker builds only when the output runs on macOS anyway: when the toolchain can cross-compile for `darwin` (e.g. Go with `GOOS=darwin GOARCH=arm64`), or when the output is platform-independent (scripts, JARs, web assets).
  - When a native macOS build is required, use the host toolchain (Xcode Command Line Tools). If a language toolchain is missing, install it as a versioned binary per the rules above, not via Homebrew.
- Keep source and build files in a temporary directory, not in `$HOME` or the dotfiles repository.
- Install the result into `~/.local/share/<name>-<version>/` (e.g. `./configure --prefix="$HOME/.local/share/<name>-<version>"`) and symlink it into `~/.local/bin/` as above.
