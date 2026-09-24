#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck disable=SC1091
source "${PROJECT_ROOT}/lib/common.sh"
load_manifest "$PROJECT_ROOT"

failures=0
warnings=0

pass() { printf '\033[1;32mPASS\033[0m  %s\n' "$*"; }
fail() { printf '\033[1;31mFAIL\033[0m  %s\n' "$*"; failures=$((failures + 1)); }
notice() { printf '\033[1;33mWARN\033[0m  %s\n' "$*"; warnings=$((warnings + 1)); }

if detect_platform >/dev/null 2>&1; then
  pass "Supported platform: ${DISTRO} ${SYSTEM_ARCH}"
else
  fail "Unsupported operating system or architecture"
fi

check_command() {
  local name="$1"
  if command_exists "$name"; then pass "$name: $(command -v "$name")"; else fail "$name is missing"; fi
}

for command_name in git curl tar nvim go tree-sitter gopls gofumpt goimports golangci-lint dlv gomodifytags impl; do
  check_command "$command_name"
done

if command_exists nvim && [[ "$(nvim --version | head -n1)" == "NVIM v${NEOVIM_VERSION}" ]]; then
  pass "Neovim version ${NEOVIM_VERSION}"
else
  fail "Expected Neovim ${NEOVIM_VERSION}"
fi

if command_exists tree-sitter \
  && [[ "$(tree-sitter --version)" == "tree-sitter ${TREE_SITTER_VERSION}"* ]]; then
  pass "tree-sitter version ${TREE_SITTER_VERSION}"
else
  fail "Expected tree-sitter ${TREE_SITTER_VERSION}"
fi

if command_exists go && [[ "$(go version)" == *"go${GO_VERSION}"* ]]; then
  pass "Go version ${GO_VERSION}"
else
  fail "Expected Go ${GO_VERSION}"
fi

if [[ -L "$NVIM_CONFIG" && -f "${NVIM_CONFIG}/init.lua" ]]; then
  pass "Managed Neovim configuration"
else
  fail "${NVIM_CONFIG} is not the managed configuration symlink"
fi

if command_exists nvim && nvim --headless "+qa" >/dev/null 2>&1; then
  pass "Headless Neovim startup"
else
  fail "Headless Neovim startup failed"
fi

if command_exists nvim && nvim --headless \
  "+doautocmd User VeryLazy" \
  "+lua assert(vim.fn.exists(':Run') == 2); assert(vim.fn.exists(':GoRunPackage') == 2); assert(vim.fn.exists(':GoAddJSONTags') == 2); assert(vim.fn.exists(':GoRemoveJSONTags') == 2); assert(vim.fn.exists(':GoImpl') == 2); assert(vim.fn.exists(':GoDebugFile') == 2); assert(vim.fn.exists(':GoDebugPackage') == 2); assert(vim.fn.exists(':GoDebugTest') == 2); assert(vim.fn.exists(':TaskRerun') == 2); assert(vim.fn.exists(':Terminal') == 2)" \
  "+lua local dap = require('dap'); local aborted = require('config.debug').configurations()[1](); assert(aborted.program == dap.ABORT)" \
  "+qa" >/dev/null 2>&1; then
  pass "Runner, Go generation, debugging and terminal commands"
else
  fail "Runner, Go generation, debugging or terminal commands are unavailable"
fi

if [[ -n "${WT_SESSION:-}" ]]; then
  notice "Windows Terminal font cannot be verified from WSL; select JetBrainsMono Nerd Font manually."
else
  notice "Use a Nerd Font in the host terminal for all icons to render correctly."
fi

printf '\nResult: %d failure(s), %d warning(s).\n' "$failures" "$warnings"
((failures == 0))
