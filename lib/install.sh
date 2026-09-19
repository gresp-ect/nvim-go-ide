#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck disable=SC1091
source "${PROJECT_ROOT}/lib/common.sh"

load_manifest "$PROJECT_ROOT"
detect_platform

mkdir -p "$LOCAL_BIN" "$OPT_ROOT" "$RELEASES_DIR" "$STATE_DIR" "$USER_CONFIG_DIR"

install_system_dependencies() {
  local missing=()
  command_exists git || missing+=(git)
  command_exists curl || missing+=(curl)
  command_exists tar || missing+=(tar)
  command_exists gzip || missing+=(gzip)
  command_exists unzip || missing+=(unzip)
  command_exists cc || missing+=(build-essential)
  command_exists rg || missing+=(ripgrep)
  if ! command_exists fd && ! command_exists fdfind; then missing+=(fd-find); fi
  command_exists fzf || missing+=(fzf)

  ((${#missing[@]} == 0)) && return 0
  [[ "${NVIM_GO_SKIP_PACKAGES:-0}" != "1" ]] \
    || die "Missing system dependencies: ${missing[*]}"

  info "Installing system dependencies: ${missing[*]}"
  local elevate=()
  ((EUID == 0)) || elevate=(sudo)
  "${elevate[@]}" apt-get update
  "${elevate[@]}" apt-get install -y ca-certificates "${missing[@]}"
}

install_neovim() {
  if command_exists nvim && [[ "$(nvim --version | head -n1)" == "NVIM v${NEOVIM_VERSION}" ]]; then
    info "Neovim ${NEOVIM_VERSION} is already installed."
    return 0
  fi

  local target="${OPT_ROOT}/neovim/${NEOVIM_VERSION}"
  if [[ ! -x "${target}/bin/nvim" ]]; then
    local temp archive checksum_name checksum
    temp="$(mktemp -d)"
    archive="${temp}/nvim.tar.gz"
    checksum_name="NEOVIM_SHA256_${SYSTEM_ARCH^^}"
    checksum="${!checksum_name:-}"
    info "Downloading Neovim ${NEOVIM_VERSION} for ${SYSTEM_ARCH}."
    download "https://github.com/neovim/neovim/releases/download/v${NEOVIM_VERSION}/nvim-linux-${NVIM_ARCH}.tar.gz" "$archive"
    verify_sha256 "$archive" "$checksum"
    tar -xzf "$archive" -C "$temp"
    mkdir -p "$(dirname "$target")"
    mv "${temp}/nvim-linux-${NVIM_ARCH}" "$target"
    rm -rf "$temp"
  fi
  replace_symlink "${target}/bin/nvim" "${LOCAL_BIN}/nvim"
}

install_go() {
  if command_exists go && [[ "$(go version)" == "go version go${GO_VERSION} linux/${SYSTEM_ARCH}" ]]; then
    info "Go ${GO_VERSION} is already installed."
    return 0
  fi

  local target="${OPT_ROOT}/go/${GO_VERSION}"
  if [[ ! -x "${target}/bin/go" ]]; then
    local temp archive checksum_name checksum
    temp="$(mktemp -d)"
    archive="${temp}/go.tar.gz"
    checksum_name="GO_SHA256_${SYSTEM_ARCH^^}"
    checksum="${!checksum_name:-}"
    info "Downloading Go ${GO_VERSION} for ${SYSTEM_ARCH}."
    download "https://go.dev/dl/go${GO_VERSION}.linux-${SYSTEM_ARCH}.tar.gz" "$archive"
    verify_sha256 "$archive" "$checksum"
    tar -xzf "$archive" -C "$temp"
    mkdir -p "$(dirname "$target")"
    mv "${temp}/go" "$target"
    rm -rf "$temp"
  fi
  replace_symlink "${target}/bin/go" "${LOCAL_BIN}/go"
  replace_symlink "${target}/bin/gofmt" "${LOCAL_BIN}/gofmt"
}

install_tree_sitter() {
  if command_exists tree-sitter \
    && [[ "$(tree-sitter --version)" == "tree-sitter ${TREE_SITTER_VERSION}" ]]; then
    info "tree-sitter ${TREE_SITTER_VERSION} is already installed."
    return 0
  fi

  local target="${OPT_ROOT}/tree-sitter/${TREE_SITTER_VERSION}"
  if [[ ! -x "${target}/bin/tree-sitter" ]]; then
    local temp archive checksum_name checksum release_arch
    temp="$(mktemp -d)"
    archive="${temp}/tree-sitter.gz"
    checksum_name="TREE_SITTER_SHA256_${SYSTEM_ARCH^^}"
    checksum="${!checksum_name:-}"
    case "$SYSTEM_ARCH" in
      amd64) release_arch="x64" ;;
      arm64) release_arch="arm64" ;;
    esac
    info "Downloading tree-sitter ${TREE_SITTER_VERSION} for ${SYSTEM_ARCH}."
    download \
      "https://github.com/tree-sitter/tree-sitter/releases/download/v${TREE_SITTER_VERSION}/tree-sitter-linux-${release_arch}.gz" \
      "$archive"
    verify_sha256 "$archive" "$checksum"
    mkdir -p "${target}/bin"
    gzip -dc "$archive" >"${target}/bin/tree-sitter"
    chmod 0755 "${target}/bin/tree-sitter"
    rm -rf "$temp"
  fi
  replace_symlink "${target}/bin/tree-sitter" "${LOCAL_BIN}/tree-sitter"
}

tool_matches() {
  local binary="$1" module="$2" version="$3"
  [[ -x "${LOCAL_BIN}/${binary}" ]] || return 1
  "${LOCAL_BIN}/go" version -m "${LOCAL_BIN}/${binary}" 2>/dev/null \
    | grep -Fq $'\tmod\t'"${module}"$'\t'"${version}"$'\t'
}

install_go_tools() {
  local binary module version build_module target stage
  while IFS='|' read -r binary module version build_module; do
    [[ -n "$binary" && "${binary:0:1}" != "#" ]] || continue
    build_module="${build_module:-$module}"
    if tool_matches "$binary" "$build_module" "$version"; then
      info "${binary} ${version} is already installed."
      continue
    fi

    target="${OPT_ROOT}/go-tools/${binary}/${version}"
    if [[ ! -x "${target}/${binary}" ]]; then
      stage="$(mktemp -d)"
      info "Installing ${binary} ${version}."
      PATH="${LOCAL_BIN}:$PATH" GOBIN="$stage" \
        "${LOCAL_BIN}/go" install "${module}@${version}"
      mkdir -p "$(dirname "$target")"
      mv "$stage" "$target"
    fi
    replace_symlink "${target}/${binary}" "${LOCAL_BIN}/${binary}"
  done <"${PROJECT_ROOT}/manifests/go-tools.txt"
}

create_user_overrides() {
  if [[ ! -f "${USER_CONFIG_DIR}/local.lua" ]]; then
    cat >"${USER_CONFIG_DIR}/local.lua" <<'EOF'
-- Personal options, keymaps and autocommands belong here.
-- This file is preserved across nvim-go-ide updates.
EOF
  fi
  if [[ ! -f "${USER_CONFIG_DIR}/plugins.lua" ]]; then
    cat >"${USER_CONFIG_DIR}/plugins.lua" <<'EOF'
-- Return additional lazy.nvim plugin specifications from this file.
return {}
EOF
  fi
}

install_system_dependencies
ensure_shell_path
install_neovim
install_go
install_tree_sitter
install_go_tools
create_user_overrides

info "Restoring pinned plugins and validating the staged configuration."
validate_config "${PROJECT_ROOT}/config"
activate_release "$PROJECT_ROOT"
prune_releases

success "nvim-go-ide ${PROJECT_VERSION} is installed."
# shellcheck disable=SC2016
printf 'Restart your shell or run: export PATH="$HOME/.local/bin:$PATH"\n'
printf 'Then open a project with: nvim .\n'
