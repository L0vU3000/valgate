# Atomic-Gated State Map — Valgate iOS

> Single source of truth for atomic iOS work. A task may move only in the order: **Planned → RED verified → GREEN verified → Xcode registered → Committed → Pushed**.

## Workflow invariants
- No implementation source is edited before its named failing test is recorded below.
- `./.hermes/orchestration/run_test.sh` is the required test gate.
- Every source/test file change must be followed by Xcode target-registration verification.
- Every pushed task requires a fresh executor session for the next task.
- Git operations use SSH agent forwarding (`ssh -A`); HTTPS Git remotes are not used for new work.

## Completed historical baseline
| Task | Evidence | Status |
|---|---|---|
| Secure API document upload contract | Commit `6a2e331`, draft PR #7 CI green | Historical baseline |
| Native Capture implementation and unit tests | Commit `5f75419`, iOS suite 96/96 green, PR #7 CI green | Historical baseline |

## Active control-plane bootstrap
| ID | Atomic task | RED evidence | GREEN evidence | Xcode registration | Commit | Push | Status |
|---|---|---|---|---|---|---|---|
| OPS-001 | Provision Atomic-Gated control plane: state map, test gate, xcodeproj verification, SSH-agent Git transport | N/A — workflow infrastructure | 96/96 iPhone 17 Pro tests passed via `run_test.sh` | `xcodeproj` API verified app + test targets | `18fad92` | PR #7 CI green | Complete |

## Next Capture task (blocked until OPS-001 is pushed)
| ID | Atomic task | Required RED test | Required GREEN test | Status |
|---|---|---|---|---|
| CAP-001 | Prove authenticated non-production property-create → first-document-upload transaction | A focused integration test/harness that fails without the approved test session/environment | Same harness passes and records only non-secret evidence | Blocked: approved non-production environment + test identity required |
