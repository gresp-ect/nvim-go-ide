#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

for script in "$ROOT/bootstrap.sh" "$ROOT/bin/nvim-go" "$ROOT"/lib/*.sh; do
  bash -n "$script"
done

python3 -m json.tool "$ROOT/config/lazy-lock.json" >/dev/null
python3 -m json.tool "$ROOT/config/lazyvim.json" >/dev/null

grep -Fq '"LazyVim"' "$ROOT/config/lazy-lock.json"
grep -Fq 'gopls|golang.org/x/tools/gopls|v' "$ROOT/manifests/go-tools.txt"
grep -Fq 'position = "bottom"' "$ROOT/config/lua/config/terminal.lua"
grep -Fq 'position = "bottom"' "$ROOT/config/lua/config/runner.lua"

version="$("$ROOT/bin/nvim-go" version)"
[[ "$version" == "nvim-go 1.0.0" ]]

output="$(NVIM_GO_LATEST_TAG=v1.0.1 "$ROOT/bin/nvim-go" update --check)"
grep -Fq 'Target release:  v1.0.1' <<<"$output"

printf 'All static tests passed.\n'
