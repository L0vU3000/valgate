#!/usr/bin/env bash
#
# doctor-local-config.sh — read-only local config doctor for the iOS worktree.
#
# Purpose
#   Verify that this worktree has an approved, machine-local
#   Config/Secrets.xcconfig in place BEFORE a Mac build/run, so a fresh
#   worktree cannot silently reach a build with missing/placeholder config.
#
# Guarantees / non-goals
#   - Read-only: never creates, modifies, moves, or deletes any file.
#   - Never prints, logs, sources, or evaluates any config VALUE. Diagnostics
#     name keys and report redacted statuses only.
#   - Does not run Xcode, does not touch the network, does not source the
#     config, does not invoke any project-controlled executable. It only reads
#     the config file as text and consults `git` (a standard tool) for ignore
#     status, plus `stat`/`uname` for permission bits.
#   - Does not use `eval`, `source`, or command substitution on any value it
#     parses out of the config file.
#
# Exit status
#   0  all checks passed.
#   1  one or more checks failed (see redacted diagnostics).
#   2  usage error.
#
# Test-only overrides (documented here only; production callers pass nothing):
#   VALGATE_DOCTOR_CONFIG    Absolute path to the config file to inspect,
#                            instead of the default worktree Secrets.xcconfig.
#   VALGATE_DOCTOR_GIT_ROOT  Git working-tree root used for the git-ignore
#                            check, instead of the worktree containing this
#                            script. Lets the test harness run entirely inside
#                            a throwaway temporary git repo.
#
set -u

usage() {
  cat <<'EOF'
Usage: doctor-local-config.sh [-h]

Read-only doctor that verifies this worktree's machine-local
Config/Secrets.xcconfig is present, private, git-ignored, and carries
real (non-placeholder) values for the required build settings. It reports
redacted statuses only and never prints any config value.

Required build settings checked:
  VALGATE_API_BASE_URL   present, non-placeholder
  CLERK_PUBLISHABLE_KEY  present, non-placeholder, begins with "pk_"
  MAPBOX_PUBLIC_TOKEN    present, non-placeholder, begins with "pk."

Test-only environment overrides (see comments at top of this script):
  VALGATE_DOCTOR_CONFIG    path to the config file to inspect
  VALGATE_DOCTOR_GIT_ROOT  git working-tree root for the ignore check
EOF
}

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
  '') : ;;
  *) usage >&2; exit 2 ;;
esac

# Resolve this script's directory without following into project code.
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)

# Default config path: the worktree's apps/ios/Config/Secrets.xcconfig,
# i.e. one level up from this scripts/ directory.
config_file="${VALGATE_DOCTOR_CONFIG:-${script_dir}/../Config/Secrets.xcconfig}"

# Default git root: the working tree containing this script.
git_root="${VALGATE_DOCTOR_GIT_ROOT:-}"
if [ -z "${git_root}" ]; then
  git_root=$(git -C "${script_dir}" rev-parse --show-toplevel 2>/dev/null || printf '')
fi

fail_count=0
note_ok()   { printf '  OK    %-22s %s\n' "$1" "$2"; }
note_fail() { printf '  FAIL  %-22s %s\n' "$1" "$2"; fail_count=$((fail_count + 1)); }

printf 'doctor-local-config: checking local iOS build config\n'
printf '  config file: %s\n' "${config_file}"

# ---------------------------------------------------------------------------
# 1. File presence
# ---------------------------------------------------------------------------
if [ ! -f "${config_file}" ]; then
  note_fail "Config/Secrets.xcconfig" "missing (restore or link the approved machine-local file)"
  printf '\ndoctor-local-config: FAILED (%d issue(s))\n' "${fail_count}"
  exit 1
fi
note_ok "Config/Secrets.xcconfig" "present"

# ---------------------------------------------------------------------------
# 2. Git-ignored status (must never be committed)
# ---------------------------------------------------------------------------
if [ -n "${git_root}" ] && git -C "${git_root}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if git -C "${git_root}" check-ignore -q -- "${config_file}"; then
    note_ok "git-ignore" "config is git-ignored"
  else
    note_fail "git-ignore" "config is NOT git-ignored (it must never be committed)"
  fi
else
  note_fail "git-ignore" "could not determine git working tree (unable to confirm config is ignored)"
fi

# ---------------------------------------------------------------------------
# 3. File permissions — owner-only; no group/other r/w/x
# ---------------------------------------------------------------------------
case "$(uname -s)" in
  Darwin) mode=$(stat -f '%Lp' "${config_file}" 2>/dev/null || printf '') ;;
  *)      mode=$(stat -c '%a'  "${config_file}" 2>/dev/null || printf '') ;;
esac
if [ -z "${mode}" ]; then
  note_fail "permissions" "unable to read file mode"
else
  # Normalize to the trailing group+other octal digits.
  group_bit="${mode: -2:1}"
  other_bit="${mode: -1:1}"
  if [ "${group_bit}" != "0" ] || [ "${other_bit}" != "0" ]; then
    note_fail "permissions" "group/other access present; must be owner-only (chmod 600)"
  else
    note_ok "permissions" "owner-only"
  fi
fi

# ---------------------------------------------------------------------------
# Parse required keys from the config file WITHOUT sourcing or evaluating.
# Read line-by-line with the shell builtin; capture presence + first token
# only, never emitting the value.
# ---------------------------------------------------------------------------
val_api=''   ; seen_api=0
val_clerk='' ; seen_clerk=0
val_mapbox=''; seen_mapbox=0

while IFS= read -r line || [ -n "${line}" ]; do
  # Skip blank and comment-only lines (xcconfig uses // and #include? lines).
  case "${line}" in
    ''|'#'*|'//'*) continue ;;
  esac
  key="${line%%=*}"
  # Only lines that actually contain '=' assign a value.
  [ "${key}" = "${line}" ] && continue
  value="${line#*=}"
  # Trim surrounding whitespace via pure parameter expansion — no subshell,
  # no command substitution, no evaluation of the parsed value.
  key="${key#"${key%%[![:space:]]*}"}"
  key="${key%"${key##*[![:space:]]}"}"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  case "${key}" in
    VALGATE_API_BASE_URL)  seen_api=1;    val_api="${value}" ;;
    CLERK_PUBLISHABLE_KEY) seen_clerk=1;  val_clerk="${value}" ;;
    MAPBOX_PUBLIC_TOKEN)   seen_mapbox=1; val_mapbox="${value}" ;;
  esac
done < "${config_file}"

# Placeholder detector: true (0) if the value looks like a template/placeholder.
# Case-insensitive; deliberately excludes "test"/"example" so legitimate
# pk_test_* keys and staging hosts are not misflagged.
is_placeholder() {
  local v="$1"
  [ -z "${v}" ] && return 0
  # Case-insensitive match via shell option — no `tr`/subshell on the value.
  local rc=1
  shopt -s nocasematch
  case "${v}" in
    *replace*|*placeholder*|*changeme*|*your-*|*your_*|*.invalid*|*todo*|*'<'*) rc=0 ;;
  esac
  shopt -u nocasematch
  return "${rc}"
}

# ---------------------------------------------------------------------------
# 4. VALGATE_API_BASE_URL — present, non-placeholder
# ---------------------------------------------------------------------------
if [ "${seen_api}" -eq 0 ] || is_placeholder "${val_api}"; then
  note_fail "VALGATE_API_BASE_URL" "absent, empty, or placeholder-like"
else
  note_ok "VALGATE_API_BASE_URL" "present, non-placeholder"
fi

# ---------------------------------------------------------------------------
# 5. CLERK_PUBLISHABLE_KEY — present, non-placeholder, begins pk_
# ---------------------------------------------------------------------------
if [ "${seen_clerk}" -eq 0 ] || is_placeholder "${val_clerk}"; then
  note_fail "CLERK_PUBLISHABLE_KEY" "absent, empty, or placeholder-like"
elif [ "${val_clerk#pk_}" = "${val_clerk}" ]; then
  note_fail "CLERK_PUBLISHABLE_KEY" "invalid (must begin with pk_)"
else
  note_ok "CLERK_PUBLISHABLE_KEY" "present, non-placeholder"
fi

# ---------------------------------------------------------------------------
# 6. MAPBOX_PUBLIC_TOKEN — present, non-placeholder, begins pk.
# ---------------------------------------------------------------------------
if [ "${seen_mapbox}" -eq 0 ] || is_placeholder "${val_mapbox}"; then
  note_fail "MAPBOX_PUBLIC_TOKEN" "absent, empty, or placeholder-like (required for live map rendering)"
elif [ "${val_mapbox#pk.}" = "${val_mapbox}" ]; then
  note_fail "MAPBOX_PUBLIC_TOKEN" "invalid (must begin with pk.)"
else
  note_ok "MAPBOX_PUBLIC_TOKEN" "present, non-placeholder"
fi

# ---------------------------------------------------------------------------
# Result
# ---------------------------------------------------------------------------
if [ "${fail_count}" -gt 0 ]; then
  printf '\ndoctor-local-config: FAILED (%d issue(s))\n' "${fail_count}"
  exit 1
fi
printf '\ndoctor-local-config: OK\n'
exit 0
