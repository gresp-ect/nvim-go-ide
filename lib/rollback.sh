#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck disable=SC1091
source "${PROJECT_ROOT}/lib/common.sh"

[[ -d "$RELEASES_DIR" ]] || die "No installed releases are available."
current=""
[[ -L "$CURRENT_LINK" ]] && current="$(basename "$(readlink -f "$CURRENT_LINK")")"

if (($#)); then
  target="$1"
  [[ "$target" == v* ]] || target="v${target}"
else
  mapfile -t candidates < <(find "$RELEASES_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' \
    | sort -Vr | grep -Fxv "$current")
  ((${#candidates[@]})) || die "No previous release is installed."
  target="${candidates[0]}"
fi

target_dir="${RELEASES_DIR}/${target}"
[[ -x "${target_dir}/bin/nvim-go" ]] || die "Release ${target} is not installed."

info "Rolling back from ${current:-unknown} to ${target}."
PROJECT_ROOT="$target_dir" exec "${target_dir}/lib/install.sh"
