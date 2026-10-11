---
name: consult
description: Delegate to or consult other LLMs available in opencode. Use proactively to save Claude tokens by offloading large reading jobs (big logs, files, docs, codebase searches) and bulk writing (boilerplate, tests, repetitive edits) to cheaper models, and for second opinions on important decisions or bugs stuck after two attempts; also when the user types /consult. Picks a weaker or stronger model by task difficulty and treats answers as advice to verify, never as truth.
---

# Delegate to and consult external models via opencode

You (Claude) stay the lead engineer. opencode models are junior helpers and outside consultants: cheap labor and fresh perspective, but their output is unverified input.

## When to use: three modes

Every call costs Claude tokens for the prompt, the answer and verification. Use a mode only when its payoff beats that cost.

### A. Offload reading (saves tokens; the main reason to use this skill)
The delegate reads a lot and you read only a short answer. Use it whenever answering would make you read more than about 20k tokens of material whose details you don't need afterwards:
- Summarizing or extracting from large logs, test output, data dumps, long docs or specs.
- Searching a codebase: "where is X handled?", "which call sites do Y?", "how does module Z work?"
- Comparing many files, or checking a large diff for a specific pattern.

Ask for a **compact, fixed-format answer** with `file:line` references, so you can open just the lines that matter. Don't offload reading when you will need the full content in context anyway, for example to edit that file next.

### B. Offload writing (saves tokens)
The delegate writes, and you read only the diff. Use it for large, well-specified, easily checked output: boilerplate, test scaffolding, repetitive edits across many files, docstrings, mechanical migrations. Don't use it for small edits, which are cheaper to do yourself, or for subtle logic.

### C. Second opinion (costs extra tokens; buys quality)
Reserve this for when a mistake would be expensive: a design or architecture decision that is hard to reverse, a risky change, a bug that survived two serious attempts, or reviewing an important plan. Don't use it out of habit or for decisions you are confident about.

### Never
Never use it for questions you can answer from what is already in context, when the user asked you not to, or with secrets in the prompt or attached files (`.env` contents, API keys, tokens, 1Password values). Prompts go to third-party providers.

## 1. Pick a model

Run `~/.claude/skills/consult/models.sh`. It lists only models from providers that currently work (probed and cached for 24h; `--refresh` re-probes, `--all` skips the probe), sorted by output cost.

Sort the list into tiers using cost, model name, recency and your own knowledge of the model families:

| Tier | Typical signals | Use for |
|------|-----------------|---------|
| **light** | free or cheapest, `flash`, `lightning`, `lite`, `mini` | reading and summarizing, codebase search, boilerplate, mechanical edits |
| **standard** | mid-priced or recent general-purpose models | ordinary coding tasks, code review, explaining code |
| **frontier** | most expensive, `pro`, `max`, `ultra`, flagship names | second opinions, hard reasoning, architecture, subtle or concurrency bugs, security |

Rules:
- **Use the cheapest model that can do the job.** Modes A and B default to light. Move up a tier only when the task needs judgment or the light answer was poor. Mode C uses frontier.
- Free models are fine for A and B, but they are often previews that rotate out or are rate-limited.
- For a second opinion, prefer a **different model family** than Claude (skip `claude-*`), since a sibling model shares your blind spots. For high-stakes questions, ask two models from different families.
- If the model lists variants, pass `--variant high` (or `max`/`xhigh`) for frontier questions and `low` or none for light work.
- On failure (rate limit, model removed, timeout), retry once with the next model in the same tier. If a whole provider fails with an auth or subscription error, run `models.sh --refresh`.

## 2. Call it

Use `~/.claude/skills/consult/ask.sh`. It forwards all arguments to `opencode run`, prints only the model's answer text (no tool-call noise or color codes), and adds a one-line footer on stderr with the tools used, tokens and cost. Run it from the project directory or pass `--dir`. For long jobs, use `run_in_background`.

**Read-only (modes A and C)** uses the `plan` agent, which can read the repo but not edit it:

```sh
~/.claude/skills/consult/ask.sh --agent plan -m <provider/model> [--variant high] --dir <repo> "<prompt>" -f <file> ...
```

Put the prompt **before** `-f`: `-f` takes multiple values and would otherwise treat the prompt as a file name. Prefer letting the agent read files itself over `-f` for large material, since the agent can read selectively.

**Delegated edits (mode B)** use the `build` agent:

```sh
git -C <repo> status --short   # must be clean or committed first, so the model's changes are isolated
~/.claude/skills/consult/ask.sh --agent build -m <provider/model> --dir <repo> "<task>"
git -C <repo> status --short   # new files appear here, not in the diff
git -C <repo> diff --stat       # then read the diff as section 4 requires
```

Never pass `--auto`. It bypasses opencode's permission prompts.

## 3. Write the prompt

The delegate sees nothing of this conversation, so make the prompt self-contained, but keep it short. Prompt tokens are your output tokens.

- **Goal and context**: what you are trying to achieve and the constraints, in a few sentences.
- **Material**: paths to read, error messages, what has been tried. Point to files rather than pasting them.
- **One focused question or task**, with a clear definition of done for delegated work.
- **Answer format**: demand brevity and structure, such as "at most N bullets", "`file:line` plus one sentence each", or "say 'not found' rather than guessing". For mode C, also ask for reasoning, a confidence level and explicit uncertainties.
- **Don't anchor**: in mode C, don't reveal your preferred answer. Present the options neutrally, or ask open-ended.

## 4. Verify in proportion to risk

Delegates can be confidently wrong, hallucinate APIs, or miss context. Verification is mandatory, but its depth should match what is at stake, or the token savings disappear.

- **Low risk** (a summary or search result that only guides where you look next): spot-check. Open one or two of the cited `file:line` references. If they hold up, trust the rest provisionally, and correct course if something later contradicts them.
- **Medium risk** (delegated edits): read `git diff --stat`, read every changed hunk of logic in full, and skim mechanical repetition after checking a few instances. Run the tests, linters or build. Fix or revert anything wrong.
- **High risk** (facts that drive a decision, mode C advice, security or data-loss questions): verify each claim you act on against the code, docs, `--help` output or tests. Check that the functions, flags and packages it names actually exist.

Weigh disagreements on their merits. Neither defer to the delegate nor dismiss it because it disagrees with you.

Report to the user briefly: which model you used (and why that tier), what you adopted or rejected, and why. For modes A and B, one line is enough.
