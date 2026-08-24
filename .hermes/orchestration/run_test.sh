#!/usr/bin/env bash
set -euo pipefail

# Run from the repository root on the Mac executor.
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ios_dir="$repo_root/apps/ios"

if ! ruby -rxcodeproj -e 'exit 0' >/dev/null 2>&1; then
  printf '%s\n' 'ERROR: xcodeproj Ruby gem is required for Atomic-Gated target registration verification.' >&2
  exit 2
fi

xcodegen_bin="${XCODEGEN_BIN:-/opt/homebrew/bin/xcodegen}"
if [ ! -x "$xcodegen_bin" ]; then
  printf '%s\n' "ERROR: XcodeGen not found at $xcodegen_bin; set XCODEGEN_BIN to its executable path." >&2
  exit 2
fi

cd "$ios_dir"
# Project generation is the repository-declared source of truth.
"$xcodegen_bin" generate
# Use the xcodeproj gem API to prove both declared targets are present.
ruby -rxcodeproj -e '
project = Xcodeproj::Project.open("ValgateiOS.xcodeproj")
targets = project.targets.map(&:name)
abort("missing app target") unless targets.include?("ValgateiOS")
abort("missing test target") unless targets.include?("ValgateiOSTests")
'

xcodebuild \
  -project ValgateiOS.xcodeproj \
  -scheme ValgateiOS \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test
