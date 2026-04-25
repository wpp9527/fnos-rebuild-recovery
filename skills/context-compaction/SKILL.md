---
name: context-compaction
description: Compress long troubleshooting, refactor, multi-agent orchestration, or dashboard/debug sessions into a durable handoff summary before continuing work. Use when context is getting long, before a risky restart/redeploy, before handing work across sessions, or whenever the user asks to compress/summarize context for continuation.
---

# Context Compaction

Use this skill to produce a **continuation-grade summary**: not prose recap, but an execution handoff that lets work resume with minimal ambiguity.

## When to use

Trigger when any of these are true:
- The user asks to 压缩上下文 / 总结上下文 / 做 handoff
- A debugging or refactor session has many moving parts
- A restart/redeploy/config patch just happened
- Multi-agent work has produced scattered evidence
- You need a compact state bundle before continuing long work

## Output goals

A good compaction summary must preserve:
1. **Goal** — what is being solved now
2. **Constraints** — user preferences, safety/operational limits
3. **Progress** — done / in progress / blocked
4. **Decisions** — what was changed and why
5. **Evidence** — exact paths, IDs, errors, commands, hashes
6. **Next actions** — the shortest path to continue

## Required structure

Use this exact section order when producing a continuation summary:

### Goal
- Current primary objective
- Secondary objectives if still active

### Constraints & Preferences
- User-stated preferences
- Operational constraints
- Safety constraints
- Things explicitly not to change

### Progress
#### Done
- [x] Verified facts and completed actions

#### In Progress
- [ ] Active investigations or pending validations

#### Blocked
- Why blocked
- What evidence supports the block

### Key Decisions
- Decision
- Rationale
- Tradeoff if relevant

### Evidence / Exact identifiers
Preserve exact opaque values when they matter:
- task IDs
- run IDs
- session keys
- file paths
- URLs
- ports
- hashes
- raw error strings
- exact model identifiers

### Pending user asks
- Explicit unresolved asks from the user

### Recommended next step
- 1–3 concrete next actions only

## Rules

- Prefer bullets over prose.
- Preserve exact strings verbatim when operationally important.
- Do **not** sanitize away task IDs, model IDs, paths, ports, or raw errors unless secrets are involved.
- Separate **facts** from **inference**.
- If uncertain, mark it clearly as a hypothesis.
- Keep the summary continuation-oriented: include what someone should do next, not just what happened.

## Good style

- Dense, direct, low-fluff
- Chinese by default if the user is using Chinese
- Short headers, precise bullets
- Use checklists for status

## Compact summary template

```md
## Goal
- ...

## Constraints & Preferences
- ...

## Progress
### Done
- [x] ...

### In Progress
- [ ] ...

### Blocked
- ...

## Key Decisions
- ...

## Evidence / Exact identifiers
- ...

## Pending user asks
- ...

## Recommended next step
1. ...
2. ...
```

## Special case: debugging/refactor sessions

When the session is a debug/refactor effort, also capture:
- current root-cause hypothesis
- what has been ruled out
- which files were patched
- whether runtime has already picked up the patch
- rollback point if the latest change fails

## Special case: multi-agent orchestration

Also capture:
- which agents were tested
- which agents are stable / unstable
- exact failure modes per agent
- whether failure is model-side, routing-side, state-machine-side, or data-source-side

## Special case: before restart or config patch

Include:
- current config hash if known
- exact patch intent
- expected blast radius
- validation checklist after restart
