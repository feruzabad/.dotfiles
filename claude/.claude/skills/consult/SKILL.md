---
name: consult
description: Consult or delegate to other LLMs available in opencode as an external consultant. Use proactively for a second opinion before non-trivial design decisions or risky changes, when stuck on a bug after two attempts, to review a plan or diff, or to offload simple well-specified bulk work; also when the user types /consult. Picks a weaker or stronger model automatically by task difficulty and treats the answer as advice to verify, never as truth.
---

# Consult external models via opencode

You (Claude) stay the lead engineer. opencode models are outside consultants and junior helpers: useful for perspective and for cheap labor, but their output is unverified input.

## When to use

Use it proactively when the benefit outweighs the time (calls take seconds to minutes):

- **Second opinion**: before a non-trivial design or architecture decision, a risky or hard-to-reverse change, or when two approaches seem equally good.
- **Stuck**: a bug that survived two serious attempts.
- **Review**: a fresh pair of eyes on your plan or diff before presenting it.
- **Delegation**: simple, well-specified, easily verified work such as boilerplate, mechanical renames, docstrings, test scaffolding or summarizing large files.

Do not use it for things faster to do yourself, for questions you can answer confidently, or when the user asked you not to. Never put secrets in a prompt or attached file (`.env` contents, API keys, tokens, 1Password values); prompts go to third-party providers.

## 1. Pick a model

Run `~/.claude/skills/consult/models.sh`. It lists only models from providers that currently work (probed and cached for 24h; `--refresh` re-probes, `--all` skips the probe), sorted by output cost.

Sort the list into tiers using cost, model name, recency and your own knowledge of the model families:

| Tier | Typical signals | Use for |
|------|-----------------|---------|
| **light** | free or cheapest, `flash`, `lightning`, `lite`, `mini` | mechanical edits, summaries, simple lookups, boilerplate |
| **standard** | mid-priced or recent general-purpose models | ordinary coding tasks, code review, explaining code |
| **frontier** | most expensive, `pro`, `max`, `ultra`, flagship names | hard reasoning, architecture, subtle or concurrency bugs, security questions |

Free models are fine, but they are often previews that rotate out or are rate-limited. Prefer a paid model of the same tier when one is usable and the task matters.

Rules:
- Match the tier to the task's difficulty. Don't spend frontier models on trivia, and don't ask light models for architecture advice.
- For a real second opinion, prefer a **different model family** than Claude (skip `claude-*`), since a sibling model shares your blind spots.
- For high-stakes questions, ask **two models from different families** and compare their answers.
- If the model lists variants, pass `--variant high` (or `max`/`xhigh`) for frontier questions and `low` or none for light work.
- On failure (rate limit, model removed, timeout), retry once with the next model in the same tier. If a whole provider fails with an auth or subscription error, run `models.sh --refresh`.

## 2. Call it

Run the commands from the project directory or pass `--dir`. For long jobs, use `run_in_background`.

**Consultation (read-only)** uses the `plan` agent, which can read the repo but not edit it:

```sh
opencode run --agent plan -m <provider/model> [--variant high] --dir <repo> "<prompt>" -f <file> ...
```

Put the prompt **before** `-f`: `-f` takes multiple values and would otherwise treat the prompt as a file name.

**Delegated job (may edit files)** uses the `build` agent:

```sh
git -C <repo> status --short   # must be clean or committed first, so the model's changes are isolated
opencode run --agent build -m <provider/model> --dir <repo> "<task>"
git -C <repo> status --short   # new files appear here, not in the diff
git -C <repo> diff              # review everything it changed
```

Never pass `--auto`. It bypasses opencode's permission prompts.

## 3. Write the prompt

The consultant sees nothing of this conversation, so make the prompt self-contained:

- **Goal and context**: what the project is, what you are trying to achieve, and the constraints.
- **Material**: relevant file paths (attach them with `-f`, or let the agent read them), error messages, what has been tried.
- **One focused question or task**, with a clear definition of done for delegated work.
- **Ask for** reasoning, a confidence level, and explicit uncertainties or assumptions.
- **Don't anchor**: when you want an independent opinion, don't reveal your preferred answer. Present the options neutrally, or ask open-ended.

## 4. Treat the answer as advice, not truth

Consultants can be confidently wrong, hallucinate APIs, or miss context. Before acting on anything:

- **Verify** factual claims against the code, docs, `--help` output or tests. Check that the functions, flags and packages it names actually exist.
- **Weigh disagreements on their merits.** Neither defer to the consultant nor dismiss it because it disagrees with you. If it raises a point you missed, take it; if its argument is weaker, say why.
- **For delegated edits**, read the full `git diff`, run the tests or linters, and fix or revert anything wrong. You own the result.
- **Report to the user** briefly: which model you consulted (and why that tier), what you adopted, what you rejected, and why.
