#!/usr/bin/env bash
# Print local Ollama models that can drive an opencode agent, one JSON object per line:
#   {"id", "params", "size_gb", "loaded", "context"}
# Only models stored on this machine with tool-calling support are included; Ollama cloud
# models are skipped. Prints nothing (exit 0) when the Ollama server is not running.
#
# "context" is the window Ollama actually serves, not the model's native maximum:
# OLLAMA_CONTEXT_LENGTH if set, else the loaded model's window, else the server's
# memory-based default from its log, else Ollama's historic default of 4096.
set -euo pipefail

api="${OLLAMA_HOST:-http://localhost:11434}"
api="${api%/}"
[[ $api == http* ]] || api="http://$api"

tags=$(curl -fsS --max-time 3 "$api/api/tags" 2>/dev/null) || exit 0
ps=$(curl -fsS --max-time 3 "$api/api/ps" 2>/dev/null || echo '{"models":[]}')

default_ctx="${OLLAMA_CONTEXT_LENGTH:-}"
if [[ -z $default_ctx ]]; then
  default_ctx=$(grep -ho 'default_num_ctx=[0-9]*' ~/.ollama/logs/server.log 2>/dev/null | tail -1 | cut -d= -f2 || true)
fi
default_ctx="${default_ctx:-4096}"

jq -r '.models[] | select(.remote_host == null and (.name | test("cloud") | not)) | .name' <<<"$tags" |
  while read -r name; do
    caps=$(curl -fsS --max-time 5 "$api/api/show" -d "$(jq -nc --arg m "$name" '{model: $m}')" 2>/dev/null |
      jq -c '.capabilities // []') || continue
    jq -c --arg name "$name" --argjson caps "$caps" --argjson ps "$ps" --argjson ctx "$default_ctx" '
      .models[] | select(.name == $name and ($caps | index("tools"))) |
      ($ps.models | map(select(.name == $name)) | .[0]) as $loaded |
      {
        id: "ollama/\(.name)",
        # MLX models report no parameter size; fall back to the tag, e.g. "gemma4:12b" -> "12B".
        params: (if (.details.parameter_size // "") != "" then .details.parameter_size
                 else ((.name | capture(":(?<p>[0-9.]+)[bB]").p + "B") // "?") end),
        size_gb: (.size / 1e9 * 10 | round / 10),
        loaded: ($loaded != null),
        context: (if env.OLLAMA_CONTEXT_LENGTH then $ctx else ($loaded.context_length // $ctx) end)
      }' <<<"$tags"
  done
