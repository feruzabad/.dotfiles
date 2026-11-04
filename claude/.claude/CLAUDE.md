<!-- This file is maintained by Claude. Edit via Claude so the structure stays consistent. -->

# Global Rules

## Editing this file

- **When the user asks to add something to CLAUDE.md, never paste their wording verbatim.** Proofread it, resolve ambiguity, and rewrite it as clear, direct instructions optimized for Claude's understanding.
- Fit new rules into the existing structure (merge with related rules, avoid duplicates), and keep the maintenance note at the top.

## Plan mode

- **Plan mode is for brainstorming and planning, not implementation.** Do not offer to implement, write project files, commit, or propose "next step: build it".
- **Use it to close knowledge gaps.** Ask targeted questions (AskUserQuestion), surface unknowns and assumptions, and keep asking in rounds until the remaining gaps can only be closed by research or by a later decision.

## macOS: installing software

- **Never use Homebrew.** Do not run `brew` or suggest it as an option.
- **Before installing, upgrading, or compiling any software, load the `macos-install` skill** and follow it (Docker-first, versioned installs, source confirmation, install log).

## API credentials (`~/api.env`)

- **Credentials live in `~/api.env`,** a 1Password Environment mounted as a file. It exists only while the mount is enabled; if the file is missing, tell the user to enable the mount instead of searching elsewhere.
- **Run any command that needs credentials through `op run`:** `op run --env-file="$HOME/api.env" -- <command>`. The secrets exist only for that subprocess, and `op run` masks them in output. For pipelines or shell expansion, wrap the command: `op run --env-file="$HOME/api.env" -- sh -c '<commands>'`.
- **Do not source the file into the shell** unless `op run` cannot be used.
- **Never print or store values.** Do not `cat`, echo, or log the file or any variable, never use `--no-masking`, and do not copy secrets into files, commits, or messages. To see what is available, list names only: `sed -E 's/=.*//' ~/api.env`.
- **Pick variables by name prefix,** which follows each tool's own convention. Check the names first, then use only what the task needs.
- **Multi-line values** (such as private keys) work through `op run`. Do not write them to disk.

## GitHub (`gh`)

- **Use the `gh` CLI for every GitHub operation** (repositories, pull requests, issues, releases, API calls), not raw `curl` or the web UI. Check `gh auth status` first if a command fails.
- **Creating a repository:** ask whether it should be private or public (recommend private), give it a short one-line description, and create it from the local repository so `origin` is set and the branch is pushed:
  `gh repo create <owner>/<name> --private --description "<one line>" --source . --remote origin --push`
- **Push only when the user asks.** Never force-push without the user's explicit confirmation for that push.

## Git commits

- **Make small, focused commits.** Group related changes into one commit per logical change, and split unrelated changes into separate commits, even when they touch the same file (stage only the relevant files, or apply a partial patch with `git apply --cached` when one file holds unrelated changes). Do not bundle everything into one large commit.
- **Use the Conventional Commits format:** `<type>(<optional scope>): <summary>`
  - Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.
  - Write the summary in the imperative mood and lowercase, with no trailing period, and keep it to about 72 characters or fewer.
  - Mark breaking changes with `!` after the type/scope (e.g. `feat(api)!: ...`) and a `BREAKING CHANGE:` footer.
  - Add a body when the reason for the change isn't obvious from the summary.
