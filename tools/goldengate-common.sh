#!/usr/bin/env bash

gg_die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

gg_bool01() {
  case "${1:-}" in
    0|1) return 0 ;;
    *) return 1 ;;
  esac
}

gg_require_int() {
  local name="$1"
  local value="$2"
  [[ "${value}" =~ ^[0-9]+$ ]] || gg_die "${name} must be an integer"
}

gg_require_number() {
  local name="$1"
  local value="$2"
  [[ "${value}" =~ ^[0-9]+([.][0-9]+)?$ ]] || gg_die "${name} must be numeric"
}

gg_require_execute_confirm() {
  local env_name="$1"
  local expected="$2"
  local dry_run="$3"
  if [[ "${dry_run}" == "1" ]]; then
    return 0
  fi
  [[ "${!env_name:-}" == "${expected}" ]] ||
    gg_die "real execution requires ${env_name}=${expected}"
}

gg_require_command_env() {
  local name="$1"
  [[ -n "${!name:-}" ]] || gg_die "missing required command environment: ${name}"
}

gg_run_step() {
  local dry_run="$1"
  local name="$2"
  local command="$3"

  printf '\n== %s ==\n' "${name}"
  printf '+ %s\n' "${command}"
  if [[ "${dry_run}" == "1" ]]; then
    return 0
  fi
  bash -lc "${command}"
}

gg_extract_temperature_c() {
  local text="$1"
  local value
  value=$(printf '%s\n' "${text}" | sed -n \
    -e 's/.*"temperature_c"[[:space:]]*:[[:space:]]*\([0-9.][0-9.]*\).*/\1/p' \
    -e 's/^temperature_c=\([0-9.][0-9.]*\).*/\1/p' |
    head -1)
  [[ -n "${value}" ]] || return 1
  printf '%s\n' "${value}"
}

gg_temp_le() {
  local temp="$1"
  local max="$2"
  awk -v t="${temp}" -v m="${max}" 'BEGIN { exit !(t <= m) }'
}

gg_header() {
  local schema="$1"
  printf '%s_start_utc=%s\n' "${schema}" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf 'schema=%s\n' "${schema}"
}

