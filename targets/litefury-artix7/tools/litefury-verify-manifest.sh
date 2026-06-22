#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/../../.." && pwd)"
manifest="${1:-}"
[[ -n "${manifest}" ]] || {
  printf 'usage: %s manifest.json\n' "$0" >&2
  exit 2
}
"${repo_root}/tools/manifest-check.sh" "${manifest}"

