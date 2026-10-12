<!-- This file is maintained by Claude. Edit via Claude so the structure stays consistent. -->

# Global Rules

## Editing this file

- **When the user asks to add something to CLAUDE.md, never paste their wording verbatim.** Proofread it, resolve ambiguity, and rewrite it as clear, direct instructions optimized for Claude's understanding.
- Fit new rules into the existing structure (merge with related rules, avoid duplicates), and keep the maintenance note at the top.

## macOS: installing software

- **Never use Homebrew.** Do not run `brew` or suggest it as an option.
- **Before installing, upgrading, or compiling any software, load the `macos-install` skill** and follow it (Docker-first, versioned installs, source confirmation, install log).

## External consultants (opencode)

- **Use the `consult` skill proactively** to offload large reading jobs and bulk writing to cheaper models; reserve second opinions for important decisions and stubborn bugs.
- **Use local Ollama models for confidential material**, never Ollama cloud models.
- **Never accept a delegate's answer as truth.** Verify it in proportion to the risk and tell the user what you adopted or rejected.

## Git commits

- **Make small, focused commits.** Group related changes into one commit per logical change, and split unrelated changes into separate commits, even when they touch the same file (stage only the relevant files, or apply a partial patch with `git apply --cached` when one file holds unrelated changes). Do not bundle everything into one large commit.
- **Use the Conventional Commits format:** `<type>(<optional scope>): <summary>`
  - Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.
  - Write the summary in the imperative mood and lowercase, with no trailing period, and keep it to about 72 characters or fewer.
  - Mark breaking changes with `!` after the type/scope (e.g. `feat(api)!: ...`) and a `BREAKING CHANGE:` footer.
  - Add a body when the reason for the change isn't obvious from the summary.
