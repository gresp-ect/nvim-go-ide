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
grep -Fq '{ "go", "test", "-json", "-coverprofile="' "$ROOT/config/lua/config/go_test.lua"
grep -Fq 'vim.cmd("cfirst")' "$ROOT/config/lua/config/go_test.lua"
grep -Fq 'line_hl_group = "GoCoverageUncovered"' "$ROOT/config/lua/config/go_test.lua"
grep -Fq 'GoTestNearest' "$ROOT/config/lua/config/keymaps.lua"
grep -Fq 'GoTestPackage' "$ROOT/config/lua/config/keymaps.lua"
grep -Fq 'go = { "goimports", "gofumpt" }' "$ROOT/config/lua/plugins/go.lua"
grep -Fq 'opts.linters_by_ft.go = nil' "$ROOT/config/lua/plugins/go.lua"
grep -Fq 'pattern = "*.go"' "$ROOT/config/lua/config/autocmds.lua"
grep -Fq 'test = { "go", "test", "." }' "$ROOT/config/lua/config/save_check.lua"
grep -Fq 'vet = { "go", "vet", "." }' "$ROOT/config/lua/config/save_check.lua"
grep -Fq 'GoSaveCheckOutput' "$ROOT/config/lua/config/keymaps.lua"

expected_version="$(sed -n 's/^PROJECT_VERSION=//p' "$ROOT/manifests/versions.env")"
version="$("$ROOT/bin/nvim-go" version)"
[[ "$version" == "nvim-go ${expected_version}" ]]

output="$(NVIM_GO_LATEST_TAG=v9.9.9 "$ROOT/bin/nvim-go" update --check)"
grep -Fq 'Target release:  v9.9.9' <<<"$output"

printf 'All static tests passed.\n'
