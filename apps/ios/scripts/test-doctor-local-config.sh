#!/usr/bin/env bash
#
# test-doctor-local-config.sh — deterministic tests for doctor-local-config.sh
#
# Runs entirely inside a throwaway temporary git repo using the doctor's
# documented test-only overrides (VALGATE_DOCTOR_CONFIG / VALGATE_DOCTOR_GIT_ROOT).
# It never touches the real worktree config, never hits the network, and
# cleans up its temporary state on exit.
#
# Fixture values use obvious dummy markers that must NEVER appear in the
# doctor's diagnostics — the leak checks below assert exactly that.
#
set -u

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
DOCTOR="${script_dir}/doctor-local-config.sh"

# Dummy, non-credential fixture markers. If any of these ever appears in the
# doctor's output, the doctor is leaking config values and the test fails.
CLERK_MARKER='TEST_SECRET_MUST_NOT_LEAK'
MAPBOX_MARKER='TEST_MAPBOX_MUST_NOT_LEAK'
CLERK_VALID="pk_test_${CLERK_MARKER}"
MAPBOX_VALID="pk.${MAPBOX_MARKER}"
API_VALID='https://api.staging.valgate.internal'

TMP=$(mktemp -d 2>/dev/null || mktemp -d -t doctor)
cleanup() { rm -rf "${TMP}"; }
trap cleanup EXIT

# Minimal throwaway git repo that ignores the config path.
git -C "${TMP}" init -q
mkdir -p "${TMP}/apps/ios/Config"
printf 'apps/ios/Config/Secrets.xcconfig\n' > "${TMP}/.gitignore"

CONFIG="${TMP}/apps/ios/Config/Secrets.xcconfig"

pass=0
fail=0
ok()   { printf '  ok   - %s\n' "$1"; pass=$((pass + 1)); }
bad()  { printf '  FAIL - %s\n' "$1"; fail=$((fail + 1)); }

# write_config <api> <clerk> <mapbox> [omit-key]
# When the 4th arg names a key, that key line is omitted entirely.
write_config() {
  local api="$1" clerk="$2" mapbox="$3" omit="${4:-}"
  : > "${CONFIG}"
  [ "${omit}" = "VALGATE_API_BASE_URL" ]  || printf 'VALGATE_API_BASE_URL = %s\n'  "${api}"    >> "${CONFIG}"
  [ "${omit}" = "CLERK_PUBLISHABLE_KEY" ] || printf 'CLERK_PUBLISHABLE_KEY = %s\n' "${clerk}"  >> "${CONFIG}"
  [ "${omit}" = "MAPBOX_PUBLIC_TOKEN" ]   || printf 'MAPBOX_PUBLIC_TOKEN = %s\n'   "${mapbox}" >> "${CONFIG}"
  chmod 600 "${CONFIG}"
}

# run_doctor -> captures combined output in $OUT, exit code in $RC
run_doctor() {
  OUT=$(VALGATE_DOCTOR_CONFIG="${CONFIG}" VALGATE_DOCTOR_GIT_ROOT="${TMP}" \
        bash "${DOCTOR}" 2>&1)
  RC=$?
}

assert_no_leak() {
  case "${OUT}" in
    *"${CLERK_MARKER}"*)  bad "$1: LEAKED clerk marker into diagnostics" ; return ;;
    *"${MAPBOX_MARKER}"*) bad "$1: LEAKED mapbox marker into diagnostics"; return ;;
  esac
  ok "$1: no secret markers in diagnostics"
}

printf 'test-doctor-local-config: running\n'

# 1. Fully valid configuration exits 0.
write_config "${API_VALID}" "${CLERK_VALID}" "${MAPBOX_VALID}"
run_doctor
[ "${RC}" -eq 0 ] && ok "valid config exits 0" || bad "valid config expected 0, got ${RC}"
assert_no_leak "valid config"

# 2. Absent Mapbox token fails.
write_config "${API_VALID}" "${CLERK_VALID}" "" MAPBOX_PUBLIC_TOKEN
run_doctor
[ "${RC}" -ne 0 ] && ok "absent mapbox fails" || bad "absent mapbox expected nonzero, got ${RC}"
assert_no_leak "absent mapbox"

# 3. Placeholder Clerk value fails.
write_config "${API_VALID}" "replace-with-real-clerk-publishable-key" "${MAPBOX_VALID}"
run_doctor
[ "${RC}" -ne 0 ] && ok "placeholder clerk fails" || bad "placeholder clerk expected nonzero, got ${RC}"
assert_no_leak "placeholder clerk"

# 4. Non-private permissions fail (group/other readable).
write_config "${API_VALID}" "${CLERK_VALID}" "${MAPBOX_VALID}"
chmod 644 "${CONFIG}"
run_doctor
[ "${RC}" -ne 0 ] && ok "non-private permissions fail" || bad "non-private perms expected nonzero, got ${RC}"
assert_no_leak "non-private permissions"

# 5. An ignored, valid config succeeds (perms restored to owner-only).
write_config "${API_VALID}" "${CLERK_VALID}" "${MAPBOX_VALID}"
run_doctor
[ "${RC}" -eq 0 ] && ok "ignored valid config exits 0" || bad "ignored valid expected 0, got ${RC}"
assert_no_leak "ignored valid config"

# 6. Not git-ignored (valid values) fails — config must never be committable.
NG_ROOT=$(mktemp -d 2>/dev/null || mktemp -d -t doctor-ng)
git -C "${NG_ROOT}" init -q
mkdir -p "${NG_ROOT}/apps/ios/Config"          # no .gitignore entry
NG_CONFIG="${NG_ROOT}/apps/ios/Config/Secrets.xcconfig"
{ printf 'VALGATE_API_BASE_URL = %s\n' "${API_VALID}"
  printf 'CLERK_PUBLISHABLE_KEY = %s\n' "${CLERK_VALID}"
  printf 'MAPBOX_PUBLIC_TOKEN = %s\n' "${MAPBOX_VALID}"; } > "${NG_CONFIG}"
chmod 600 "${NG_CONFIG}"
OUT=$(VALGATE_DOCTOR_CONFIG="${NG_CONFIG}" VALGATE_DOCTOR_GIT_ROOT="${NG_ROOT}" \
      bash "${DOCTOR}" 2>&1); RC=$?
rm -rf "${NG_ROOT}"
[ "${RC}" -ne 0 ] && ok "not-ignored config fails" || bad "not-ignored expected nonzero, got ${RC}"

# 7. Absent config file fails.
rm -f "${CONFIG}"
run_doctor
[ "${RC}" -ne 0 ] && ok "absent config fails" || bad "absent config expected nonzero, got ${RC}"

printf '\ntest-doctor-local-config: %d passed, %d failed\n' "${pass}" "${fail}"
[ "${fail}" -eq 0 ] || exit 1
exit 0
