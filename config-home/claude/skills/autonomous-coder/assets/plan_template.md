---
task: <TASK_DESCRIPTION>
branch: <BRANCH_NAME>
iteration: 1
status: in_progress
started_at: <TIMESTAMP>
last_checkpoint: <TIMESTAMP>
---

# Implementation Plan

## Original Request

<Paste the original user request or PRD here>

## Context Budget

| Metric | Value |
|--------|-------|
| Total stories | X |
| Completed stories | 0 |
| Current context usage | ~5% |
| Target per story | 15-20% |
| Last checkpoint | <timestamp> |

**Context thresholds:**
- 30%: Checkpoint (update this file, commit WIP)
- 15%: Finalize (complete micro-task, full checkpoint)
- 10%: Clear (tell user to /clear and re-invoke)

## Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Stories

| ID | Story | Priority | Status | Context Used |
|----|-------|----------|--------|--------------|
| 1 | <story description> | high | pending | - |
| 2 | <story description> | high | pending | - |
| 3 | <story description> | medium | pending | - |

## Current Story

**ID**: 1
**Description**: <what to implement>
**Approach**: <implementation plan>

**Files to modify**:
- `path/to/file1.py`
- `path/to/file2.py`

**Acceptance for this story**:
- [ ] Sub-criterion 1
- [ ] Sub-criterion 2

**What's Done**: <nothing yet>
**What's Remaining**: <full implementation>
**Next Action**: <exact next step>

## Resume Instructions

If resuming after context clear:
1. Read this file completely
2. Check `git status` and `git log --oneline -5` for recent state
3. Continue from "Next Action" above
4. Update Context Budget section with current usage

## Learnings

Document discoveries that will help future iterations:

- <pattern or convention discovered>
- <gotcha to avoid>
- <useful file or function found>

## Progress Log

### Iteration 1
**Started**: <timestamp>
**Story**: 1
**Status**: in_progress
**Context at start**: ~5%

**Actions taken**:
- <action 1>
- <action 2>

**Validation results**:
```
<paste validation output>
```

**Checkpoint at**: <timestamp>
**Context at checkpoint**: ~X%
**Outcome**: <passed/failed - next steps>

---

## Quick Reference

### Context Checkpointing
```bash
# At 30% context - checkpoint
git add -A && git commit -m "wip: checkpoint at 30% context"

# At 15% context - finalize
git add -A && git commit -m "wip: checkpoint at 15% - ready to resume"

# At 10% context - tell user
# "Run /clear then re-invoke /autonomous-coder to resume"
```

### Validation Commands

```bash
# Python
abenv --local -- ruff check <files>
abenv --local -- pytest <test_path> --no-migrations --disable-warnings

# Go
go test -v ./...
go vet ./...

# JS
yarn --cwd <path> lint
yarn --cwd <path> test
```

### Branch Info

```bash
git branch --show-current
git log --oneline -5
git status
```
