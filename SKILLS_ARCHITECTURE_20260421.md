# Skills Architecture Baseline (2026-04-21)

## Canonical location
- `/opt/fnos-media/services/openclaw/home/.openclaw/workspace/skills`

This directory is the single source of truth for user-installed and project-local skills.

## Compatibility layer
Runtime and local business scripts still discover skills from `workspace-*/skills`.
Therefore each workspace keeps the historical path, but should resolve to the canonical directory via symlink where possible.

## Migrated on 2026-04-21
- Moved custom skills from `workspace-taizi/skills` into canonical store
- Replaced empty `workspace-*/skills` directories with symlinks to canonical store

## Cleanup policy
Safe to remove after migration:
- migrated physical duplicate skill directories in per-agent workspace
- empty per-workspace `skills/` directories replaced by symlink

Do not remove blindly:
- `/agents/*/SKILL.md` role bootstrap/config files
- bundled system skills under `/usr/lib/node_modules/openclaw/skills`
