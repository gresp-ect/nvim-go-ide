#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2016

set -euo pipefail

# These values are intentionally consumed by scripts that source this file.
# Literal shell expressions are written to the user's startup file unchanged.

PROJECT_NAME="nvim-go-ide"
REPOSITORY="gresp-ect/nvim-go-ide"
LOCAL_BIN="${HOME}/.local/bin"
OPT_ROOT="${HOME}/.local/opt/${PROJECT_NAME}"
DATA_ROOT="${HOME}/.local/share/${PROJECT_NAME}"
RELEASES_DIR="${DATA_ROOT}/releases"
CURRENT_LINK="${DATA_ROOT}/current"
STATE_DIR="${HOME}/.local/state/${PROJECT_NAME}"
BACKUP_DIR="${STATE_DIR}/backups"
USER_CONFIG_DIR="${HOME}/.config/${PROJECT_NAME}"
NVIM_CONFIG="${HOME}/.config/nvim"

# Management commands must work immediately after installation, even before a
# new interactive shell has sourced the PATH block written by the installer.
export PATH="${LOCAL_BIN}:${PATH}"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
success() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mWarning:\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31mError:\033[0m %s\n' "$*" >&2; exit 1; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

load_manifest() {
  local root="${1:-${PROJECT_ROOT}}"
  local manifest="${root}/manifests/versions.env"
  [[ -f "$manifest" ]] || die "Version manifest not found: $manifest"
  # shellcheck disable=SC1090
  source "$manifest"
  : "${PROJECT_VERSION:?Missing PROJECT_VERSION}"
  : "${NEOVIM_VERSION:?Missing NEOVIM_VERSION}"
  : "${GO_VERSION:?Missing GO_VERSION}"
}

detect_platform() {
  [[ -r /etc/os-release ]] || die "Only Ubuntu and Debian are supported."
  # shellcheck disable=SC1091
  source /etc/os-release
  case "${ID:-}" in
    ubuntu|debian) DISTRO="$ID" ;;
    *) die "Unsupported distribution '${ID:-unknown}'. Use Ubuntu or Debian." ;;
  esac

  case "$(uname -m)" in
    x86_64|amd64)
      SYSTEM_ARCH="amd64"
      NVIM_ARCH="x86_64"
      ;;
    aarch64|arm64)
      SYSTEM_ARCH="arm64"
      NVIM_ARCH="arm64"
      ;;
    *) die "Unsupported architecture: $(uname -m)" ;;
  esac
}

download() {
  local url="$1" destination="$2"
  curl --fail --location --retry 3 --retry-delay 2 --silent --show-error \
    "$url" --output "$destination"
}

verify_sha256() {
  local file="$1" expected="$2"
  [[ -n "$expected" ]] || die "No checksum is recorded for $(basename "$file")."
  printf '%s  %s\n' "$expected" "$file" | sha256sum --check --status \
    || die "Checksum verification failed for $(basename "$file")."
}

timestamp() { date -u +%Y%m%dT%H%M%SZ; }

backup_path() {
  local path="$1"
  [[ -e "$path" || -L "$path" ]] || return 0
  mkdir -p "$BACKUP_DIR"
  local name
  name="$(basename "$path").$(timestamp)"
  mv "$path" "${BACKUP_DIR}/${name}"
  info "Backed up $path to ${BACKUP_DIR}/${name}"
}

replace_symlink() {
  local target="$1" link="$2"
  mkdir -p "$(dirname "$link")"
  if [[ -L "$link" && "$(readlink -f "$link")" == "$(readlink -f "$target")" ]]; then
    return 0
  fi
  backup_path "$link"
  ln -s "$target" "$link"
}

ensure_shell_path() {
  local file="${HOME}/.bashrc"
  local start="# >>> nvim-go-ide >>>"
  if [[ -f "$file" ]] && grep -Fq "$start" "$file"; then
    return 0
  fi
  {
    printf '\n%s\n' "$start"
    printf 'export PATH="$HOME/.local/bin:$PATH"\n'
    printf 'export GOBIN="$HOME/.local/bin"\n'
    printf '%s\n' '# <<< nvim-go-ide <<<'
  } >>"$file"
}

latest_release_tag() {
  if [[ -n "${NVIM_GO_LATEST_TAG:-}" ]]; then
    printf '%s\n' "$NVIM_GO_LATEST_TAG"
    return
  fi
  local effective
  effective="$(curl --fail --location --silent --show-error --output /dev/null \
    --write-out '%{url_effective}' "https://github.com/${REPOSITORY}/releases/latest")"
  [[ "$effective" == */tag/* ]] || die "Could not resolve the latest stable release."
  printf '%s\n' "${effective##*/tag/}"
}

validate_config() {
  local config_dir="$1"
  local test_root
  test_root="$(mktemp -d)"
  mkdir -p "${test_root}/config"
  ln -s "$config_dir" "${test_root}/config/nvim"
  if ! XDG_CONFIG_HOME="${test_root}/config" \
    "${LOCAL_BIN}/nvim" --headless "+Lazy! restore" "+qa"; then
    rm -rf "$test_root"
    die "Neovim configuration validation failed. The active release was not changed."
  fi
  rm -rf "$test_root"
}

activate_release() {
  local release_root="$1"
  replace_symlink "$release_root" "$CURRENT_LINK"
  replace_symlink "${release_root}/config" "$NVIM_CONFIG"
  replace_symlink "${CURRENT_LINK}/bin/nvim-go" "${LOCAL_BIN}/nvim-go"
  printf '%s\n' "$(basename "$release_root")" >"${STATE_DIR}/active-version"
}

prune_releases() {
  [[ -d "$RELEASES_DIR" ]] || return 0
  mapfile -t releases < <(find "$RELEASES_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort -V)
  while ((${#releases[@]} > 3)); do
    local oldest="${releases[0]}"
    if [[ -L "$CURRENT_LINK" && "$(basename "$(readlink -f "$CURRENT_LINK")")" == "$oldest" ]]; then
      break
    fi
    rm -rf "${RELEASES_DIR:?}/${oldest}"
    releases=("${releases[@]:1}")
  done
}
