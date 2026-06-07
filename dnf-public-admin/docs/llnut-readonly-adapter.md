# llnut Read-only Adapter

The first production-facing adapter phase is intentionally read-only. It is designed to connect to the existing `104 / dnf-llnut` databases without creating a second game-data source.

## Environment

Use a read-only MySQL user. Do not use `root` or the game write user for the MVP adapter.

```env
LLNUT_MYSQL_HOST=127.0.0.1
LLNUT_MYSQL_PORT=3306
LLNUT_MYSQL_READONLY_USER=dnf_readonly
LLNUT_MYSQL_READONLY_PASSWORD=change-me
```

The adapter selects one of the approved legacy databases per query domain:

- `d_taiwan`
- `taiwan_login`
- `taiwan_cain`
- `taiwan_cain_2nd`
- `taiwan_billing`

`dnf_service` and other candidate/admin databases are not game-data sources for the llnut adapter.

## Safety checks

- `BuildMySQLDSN` rejects `root`.
- `BuildMySQLDSN` rejects databases outside the legacy llnut baseline.
- `ValidateReadOnlySchema` verifies required legacy columns before an adapter is promoted from demo data to live reads.
- `POST /api/v1/meta/llnut-schema/validate` can be used by deployment tooling to validate inspected table metadata.

## Promotion gate

Before enabling live reads in production:

1. Inspect the 104 schema using a read-only account.
2. Validate the inspected metadata through `/api/v1/meta/llnut-schema/validate`.
3. Compare read results with the old `882` admin panel.
4. Keep write operations disabled until RBAC and audit logging are verified.


## Mode switch

```env
LLNUT_MODE=demo
```

Allowed values:

- `demo` — default, safe preview data.
- `live-readonly` — production read-only mode after schema validation.

Any other value falls back to `demo`. There is no write mode in the current codebase.
