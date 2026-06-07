# Legacy Compatibility Baseline

This project must remain compatible with the existing `104 / dnf-llnut` deployment until the new admin panel is explicitly promoted.

## Source of Truth

- Runtime host: `104 / 192.168.1.204`
- Runtime project: `dnf-llnut`
- Runtime image: `llnut/dnf:debian13-qf1031-latest`
- Existing admin panel: `dnf-console`

The existing admin panel and the llnut game databases remain the source of truth. The new admin panel must not create a parallel game dataset or silently migrate game data.

## Legacy Ports

| Purpose | Port |
| --- | ---: |
| DNF admin / dnf-console | `882` |
| Supervisor | `2000` |
| Game login / launcher-facing service | `3000` |

The private deployment repository should keep these mappings by default. If a preview instance is needed, run it on a separate preview port and document the difference explicitly.

## Legacy Databases

The llnut adapter must target the existing game database names unless a future migration plan is approved.

| Domain | Database |
| --- | --- |
| Accounts | `d_taiwan` |
| Login | `taiwan_login` |
| Cain game data | `taiwan_cain` |
| Cain secondary data | `taiwan_cain_2nd` |
| Billing | `taiwan_billing` |

## Data Safety Rules

1. Start with read-only account, character, inventory, activity, and PVF checks.
2. Do not duplicate game data into a new authoritative database.
3. Admin/RBAC/audit data may live in the new admin database, but game operations must reference existing llnut IDs.
4. Every write operation must be gated by RBAC and audit logging before it can be enabled.
5. `onlyGuo/dnf-server-public` remains a reference/candidate system, not the production source of truth.

## API Guardrail

`GET /api/v1/meta/llnut-baseline` exposes the baseline used by the backend and has tests to catch accidental port/database drift.
