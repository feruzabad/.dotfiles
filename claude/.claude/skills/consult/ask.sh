#!/usr/bin/env bash
# Run `opencode run` and print only the model's answer text, dropping tool-call noise
# and ANSI codes so the caller reads as few tokens as possible.
# A one-line footer on stderr summarizes the tools used, tokens and cost.
# Usage: ask.sh <opencode run args...>   e.g. ask.sh --agent plan -m deepseek/deepseek-flash "<prompt>"
set -euo pipefail

log=$(mktemp)
trap 'rm -f "$log"' EXIT

status=0
opencode run --format json "$@" >"$log" 2>/dev/null || status=$?

jq -rj '
  if .type == "text" then (.part.text // "") + "\n"
  elif .type == "error" then "ERROR: " + ((.error.data.message // .error.message // .error) | tostring) + "\n"
  else empty end' "$log"

jq -rs '
  (map(select(.type == "tool_use") | .part.tool) | group_by(.) | map("\(.[0])×\(length)") | join(" ")) as $tools
  | (map(select(.type == "step_finish") | .part)) as $steps
  | "[\($steps | length) steps; tools: \(if $tools == "" then "none" else $tools end);"
    + " tokens in \($steps | map(.tokens.input + .tokens.cache.read) | add // 0)"
    + " out \($steps | map(.tokens.output + .tokens.reasoning) | add // 0);"
    + " cost $\($steps | map(.cost) | add // 0 | . * 10000 | round / 10000)]"' "$log" >&2

exit "$status"
