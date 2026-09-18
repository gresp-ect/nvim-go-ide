#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck disable=SC1091
source "${PROJECT_ROOT}/lib/common.sh"
load_manifest "$PROJECT_ROOT"

check_only=0
dry_run=0
requested=""

while (($#)); do
  case "$1" in
    --check) check_only=1 ;;
    --dry-run) dry_run=1 ;;
    --version)
      shift
      (($#)) || die "--version requires a value."
      requested="$1"
      ;;
    -h|--help)
      printf 'Usage: nvim-go update [--check] [--dry-run] [--version VERSION]\n'
      exit 0
      ;;
    *) die "Unknown update option: $1" ;;
  esac
  shift
done

target_tag="${requested:-$(latest_release_tag)}"
[[ "$target_tag" == v* ]] || target_tag="v${target_tag}"
current_tag="v${PROJECT_VERSION}"

if [[ "$target_tag" == "$current_tag" ]]; then
  success "Already up to date (${current_tag})."
  exit 0
fi

info "Current release: ${current_tag}"
info "Target release:  ${target_tag}"
((check_only == 0 && dry_run == 0)) || exit 0

mkdir -p "$RELEASES_DIR"
target_dir="${RELEASES_DIR}/${target_tag}"
if [[ ! -x "${target_dir}/bin/nvim-go" ]]; then
  temp="$(mktemp -d)"
  stage="${RELEASES_DIR}/.${target_tag}.tmp.$$"
  trap 'rm -rf "$temp" "$stage"' EXIT
  asset="${PROJECT_NAME}-${target_tag}.tar.gz"
  base="https://github.com/${REPOSITORY}/releases/download/${target_tag}"
  info "Downloading ${asset}."
  download "${base}/${asset}" "${temp}/${asset}"
  download "${base}/SHA256SUMS" "${temp}/SHA256SUMS"
  expected="$(awk -v name="$asset" '$2 == name { print $1 }' "${temp}/SHA256SUMS")"
  verify_sha256 "${temp}/${asset}" "$expected"
  rm -rf "$stage"
  mkdir -p "$stage"
  tar -xzf "${temp}/${asset}" --strip-components=1 -C "$stage"
  [[ -x "${stage}/bin/nvim-go" ]] || die "The release archive is incomplete."
  rm -rf "$target_dir"
  mv "$stage" "$target_dir"
  rm -rf "$temp"
  trap - EXIT
fi

info "Installing and validating ${target_tag}."
PROJECT_ROOT="$target_dir" exec "${target_dir}/lib/install.sh"
