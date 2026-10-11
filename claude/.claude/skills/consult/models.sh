#!/usr/bin/env bash
# List usable opencode models as a compact table, cheapest output cost first.
# Columns: id, input $/M tokens, output $/M tokens, context, reasoning, variants, release date.
#
# Having credentials does not mean a provider works (e.g. an expired subscription), so each
# provider is probed once with its cheapest model and the result is cached for 24h.
#   --all      skip the probe and list every active model
#   --refresh  re-probe providers now
set -euo pipefail

cache="${XDG_CACHE_HOME:-$HOME/.cache}/opencode-consult/providers.tsv"
probe_timeout=45
all=false refresh=false
for arg in "$@"; do
  case "$arg" in
    --all) all=true ;;
    --refresh) refresh=true ;;
    *) echo "usage: ${0##*/} [--all] [--refresh]" >&2; exit 2 ;;
  esac
done

# One JSON object per line, active models only, sorted by output cost.
models=$(
  opencode models --verbose 2>/dev/null |
    awk '/^[A-Za-z0-9._-]+\/[^ ]+$/ { if (buf) print buf; buf = ""; next } { buf = buf $0 } END { if (buf) print buf }' |
    jq -c -s 'map(select(.status == "active")) | sort_by(.cost.output // 0) | .[]'
)

if ! $all; then
  if $refresh || [[ ! -s $cache ]] || [[ -n $(find "$cache" -mmin +1440) ]]; then
    mkdir -p "${cache%/*}"
    workdir=$(mktemp -d)
    : >"$cache.tmp"
    for provider in $(jq -r '.providerID' <<<"$models" | sort -u); do
      model=$(jq -r --arg p "$provider" 'select(.providerID == $p) | "\(.providerID)/\(.id)"' <<<"$models" | head -1)
      # perl stands in for coreutils timeout, which macOS lacks.
      # The child gets its own process group so the timeout also kills opencode's descendants.
      if (cd "$workdir" && perl -e '$t = shift; $pid = fork // die; unless ($pid) { setpgrp; exec @ARGV }
        $SIG{ALRM} = sub { kill "TERM", -$pid; exit 124 }; alarm $t; waitpid $pid, 0; exit $? >> 8' "$probe_timeout" \
        opencode run -m "$model" "Reply with exactly: OK" 2>&1) | grep -q 'OK'; then
        printf '%s\tok\n' "$provider" >>"$cache.tmp"
      else
        printf '%s\tfail\n' "$provider" >>"$cache.tmp"
      fi
    done
    rm -rf "$workdir"
    mv "$cache.tmp" "$cache"
  fi
  usable=$(awk -F'\t' '$2 == "ok" { print $1 }' "$cache" | jq -R . | jq -cs .)
  models=$(jq -c --argjson ok "$usable" 'select(.providerID as $p | $ok | index($p))' <<<"$models")
  failed=$(awk -F'\t' '$2 == "fail" { print $1 }' "$cache" | paste -sd, -)
  [[ -n $failed ]] && echo "unusable providers (cached, --refresh to re-probe): $failed" >&2
fi

jq -rs '
  (["id", "in$/M", "out$/M", "context", "reasoning", "variants", "released"] | @tsv),
  (.[] | [
    "\(.providerID)/\(.id)",
    (.cost.input // 0), (.cost.output // 0),
    (.limit.context // 0),
    (.capabilities.reasoning // false),
    ((.variants // {}) | keys | join(",") | if . == "" then "-" else . end),
    (.release_date // "")
  ] | @tsv)' <<<"$models" |
  column -t -s $'\t'

local_models=$("${0%/*}/ollama-models.sh")
if [[ -n $local_models ]]; then
  echo
  echo "local (Ollama; free, private, slower; context is what Ollama serves, not the model maximum):"
  jq -rs '
    (["id", "params", "size_GB", "context", "loaded"] | @tsv),
    (sort_by(.size_gb) | .[] | [.id, .params, .size_gb, .context, (if .loaded then "yes" else "no" end)] | @tsv)' <<<"$local_models" |
    column -t -s $'\t'
fi
