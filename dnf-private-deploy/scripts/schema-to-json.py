#!/usr/bin/env python3
import json
import sys

tables = {}
for raw in sys.stdin:
    line = raw.strip()
    if not line:
        continue
    if '\t' in line:
        table, columns = line.split('\t', 1)
    elif ' ' in line:
        table, columns = line.split(None, 1)
    else:
        continue
    tables[table] = [c for c in columns.split(',') if c]

json.dump({"tables": tables}, sys.stdout, ensure_ascii=False, indent=2)
print()
