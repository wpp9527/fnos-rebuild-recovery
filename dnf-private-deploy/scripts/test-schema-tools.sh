#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
json="$($ROOT_DIR/scripts/schema-inspect.sh --example-json)"
SCHEMA_JSON="$json" python3 - <<'PY'
import json, os
payload=json.loads(os.environ['SCHEMA_JSON'])
assert 'tables' in payload
assert payload['tables']['d_taiwan.accounts'][:2] == ['UID', 'accountname']
print('schema-tools-ok')
PY
