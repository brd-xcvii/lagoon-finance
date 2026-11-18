#!/usr/bin/env bash
# Fails if anything that looks like an API key is in the files given (or in every tracked file).
# Lagoon keeps keys on the phone only. This is the backup check that stops one reaching GitHub.
set -u
files=("$@")
if [ ${#files[@]} -eq 0 ]; then mapfile -t files < <(git ls-files); fi
patterns=(
  'sk-ant-[A-Za-z0-9_-]{20,}'                      # Anthropic API key
  'sk_[0-9a-fA-F]{40,}'                            # ElevenLabs API key
  'sk-(proj-)?[A-Za-z0-9_-]{32,}'                  # OpenAI style key
  '\b[0-9a-fA-F]{60,}\b'                           # long hex: PocketSmith developer keys and similar
  '[Xx]-[Dd]eveloper-[Kk]ey["'"'"' :]+[A-Za-z0-9]{16,}'  # a PocketSmith key written next to its header
  'x-api-key["'"'"' :]+[A-Za-z0-9_-]{16,}'          # a key written next to its header
)
found=0
for f in "${files[@]}"; do
  [ -f "$f" ] || continue
  grep -Iq . "$f" 2>/dev/null || continue   # skip images and other binary files
  for p in "${patterns[@]}"; do
    if grep -EnI "$p" "$f" >/dev/null 2>&1; then
      echo "Possible API key in $f (pattern: $p)"; grep -EnoI "$p" "$f" | sed -E 's/(:[^:]{6})[^:]*$/\1…hidden/' ; found=1
    fi
  done
done
if [ "$found" -ne 0 ]; then echo "Blocked: remove the key. Keys belong in Lagoon's settings on the phone, never in the code."; exit 1; fi
echo "No API keys found."
