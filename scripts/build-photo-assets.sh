#!/usr/bin/env bash
set -euo pipefail

manifest=".site-assets/photo-manifest.tsv"

if [[ ! -f "$manifest" ]]; then
  echo "Missing photo manifest: $manifest" >&2
  exit 1
fi

mkdir -p assets

while IFS=$'\t' read -r output sha256 parts; do
  [[ -z "${output// }" ]] && continue
  [[ "$output" == \#* ]] && continue

  mkdir -p "$(dirname "$output")"
  tmp_b64="$(mktemp)"
  : > "$tmp_b64"

  IFS=',' read -ra specs <<< "$parts"
  for spec in "${specs[@]}"; do
    shopt -s nullglob
    matches=( $spec )
    shopt -u nullglob

    if (( ${#matches[@]} == 0 )); then
      echo "No photo chunks matched: $spec" >&2
      rm -f "$tmp_b64"
      exit 1
    fi

    for part in "${matches[@]}"; do
      tr -d '\r\n' < "$part" >> "$tmp_b64"
    done
  done

  b64_len="$(wc -c < "$tmp_b64")"
  if (( b64_len % 4 != 0 )); then
    echo "Invalid base64 length for $output: $b64_len" >&2
    rm -f "$tmp_b64"
    exit 1
  fi

  base64 --decode "$tmp_b64" > "$output"
  rm -f "$tmp_b64"

  echo "$sha256  $output" | sha256sum -c -

  mime="$(file -b --mime-type "$output")"
  if [[ "$mime" != "image/webp" ]]; then
    echo "Unexpected MIME for $output: $mime" >&2
    exit 1
  fi

  echo "Built and verified $output"
done < "$manifest"

rm -rf .site-assets
