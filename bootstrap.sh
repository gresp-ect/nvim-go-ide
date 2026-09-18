#!/usr/bin/env bash

set -euo pipefail

PROJECT_NAME="nvim-go-ide"
REPOSITORY="gresp-ect/nvim-go-ide"
DATA_ROOT="${HOME}/.local/share/${PROJECT_NAME}"
RELEASES_DIR="${DATA_ROOT}/releases"
LOCAL_BIN="${HOME}/.local/bin"

die() { printf 'Error: %s\n' "$*" >&2; exit 1; }
for command_name in curl tar sha256sum; do
  command -v "$command_name" >/dev/null 2>&1 || die "Required command is missing: ${command_name}"
done

effective="$(curl --fail --location --silent --show-error --output /dev/null \
  --write-out '%{url_effective}' "https://github.com/${REPOSITORY}/releases/latest")"
[[ "$effective" == */tag/* ]] || die "Could not resolve the latest stable release."
tag="${effective##*/tag/}"
asset="${PROJECT_NAME}-${tag}.tar.gz"
base="https://github.com/${REPOSITORY}/releases/download/${tag}"
temp="$(mktemp -d)"
trap 'rm -rf "$temp"' EXIT

printf 'Downloading %s...\n' "$asset"
curl --fail --location --retry 3 --silent --show-error "${base}/${asset}" --output "${temp}/${asset}"
curl --fail --location --retry 3 --silent --show-error "${base}/SHA256SUMS" --output "${temp}/SHA256SUMS"
expected="$(awk -v name="$asset" '$2 == name { print $1 }' "${temp}/SHA256SUMS")"
[[ -n "$expected" ]] || die "The release checksum is missing."
printf '%s  %s\n' "$expected" "${temp}/${asset}" | sha256sum --check --status \
  || die "Release checksum verification failed."

target="${RELEASES_DIR}/${tag}"
mkdir -p "$target" "$LOCAL_BIN"
tar -xzf "${temp}/${asset}" --strip-components=1 -C "$target"
chmod +x "${target}/bin/nvim-go" "${target}/bootstrap.sh" "${target}"/lib/*.sh
ln -sfn "$target" "${DATA_ROOT}/current"
ln -sfn "${DATA_ROOT}/current/bin/nvim-go" "${LOCAL_BIN}/nvim-go"

exec "${LOCAL_BIN}/nvim-go" install
