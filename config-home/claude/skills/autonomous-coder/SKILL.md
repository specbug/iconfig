---
name: autonomous-coder
description: Autonomous coding agent that iteratively plans, executes, validates, and refines code changes using the Ralph methodology. This skill should be used when handling coding requests, abstract implementation tasks, bug fixes, or feature development that requires planning, execution, validation cycles. Triggers on any request implying code changes and execution (not documentation or config-only changes).
---

# Autonomous Coder

An autonomous coding agent implementing the Ralph methodology for iterative software development.

## Overview

This skill transforms abstract requirements into well-tested, production-ready code through autonomous iteration cycles. Each cycle: **Plan → Execute → Validate → Refine** until completion criteria are met.

**CRITICAL**: This skill uses the ralph-loop plugin to ENFORCE iteration. You MUST invoke `/ralph-loop` at the start.

## When to Use

- Coding requests requiring implementation
- Abstract requirements needing breakdown
- Bug fixes requiring investigation and validation
- Feature development with acceptance criteria
- Any task requiring code changes AND validation

## STEP 0: Start Ralph Loop (MANDATORY)

**Before doing anything else**, invoke the ralph-loop to enforce the iterative validation cycle:

```bash
/ralph-loop "<original user request>" --completion-promise "All tests passing and code review clean" --max-iterations 20
```

This creates a stop-hook that:
- Feeds the same prompt back after each "completion"
- Forces you to validate and iterate until genuinely done
- Only exits when you output `<promise>All tests passing and code review clean</promise>` AND it's TRUE

**Do NOT output the promise tag until:**
1. All tests actually pass (show the output)
2. Lint/type checks pass (show the output)
3. Code review has no critical issues

## Core Workflow

### Phase 1: Initialize

1. **Start ralph-loop** (see Step 0 above)

2. Create/update `.claude/plan.md` with:
   - Task description and acceptance criteria
   - Breakdown into context-window-sized stories
   - Current iteration status
   - Learnings from previous iterations

3. Create feature branch if not already on one:
   ```bash
   git checkout -b $USER/pr/<descriptive-name>
   ```

### Phase 2: Plan (Each Iteration)

1. Read `.claude/plan.md` to understand current state
2. Select next incomplete story (highest priority)
3. Research the codebase using Task tool with Explore agent
4. Update plan with implementation approach for current story

### Phase 3: Execute

1. Implement the single story
2. Keep changes focused and atomic
3. Follow existing codebase patterns (check `*_dev.md` files)
4. Use appropriate tools:
   - Python: `abenv --local -- python ...`
   - Go: `go test -v ./...`
   - JS: `yarn --cwd <path> test`

### Phase 4: Validate

Run validation checks in order:

1. **Lint/Type Check**
   ```bash
   # Python
   abenv --local -- ruff check <files>
   abenv --local -- mypy <files>

   # Go
   go vet ./...

   # JS
   yarn --cwd <path> lint
   ```

2. **Tests**
   ```bash
   # Python
   abenv --local -- pytest <test_files> --no-migrations --disable-warnings

   # Go
   go test -v ./...

   # JS
   yarn --cwd <path> test
   ```

3. **Code Review** (using coderabbit CLI)
   ```bash
   coderabbit review --diff "$(git diff HEAD~1)"
   ```

### Phase 5: Commit & Update

If validation passes:
1. Stage and commit changes
2. Update `.claude/plan.md`:
   - Mark story as complete
   - Record any learnings or gotchas
   - Update progress tracking

If validation fails:
1. Analyze failure
2. Update `.claude/plan.md` with failure reason
3. Return to Phase 3 with fix

### Phase 6: Iterate or Complete

Check completion criteria:
- All stories marked complete?
- All tests passing?
- Code review clean?

If complete → Phase 7
If not → Return to Phase 2 with next story

### Phase 7: Create PR

1. Ensure all changes committed and pushed
2. Run `/pr` skill or manually:
   ```bash
   gh pr create --title "<title>" --body "$(cat <<'EOF'
   ## Summary
   <motivation>

   ## Changes
   <bullet points>

   ## Test Plan
   <actual test outputs>

   ## Deploy Plan
   <deployment steps>
   EOF
   )"
   ```

## Context Management Protocol

**CRITICAL**: Context compaction loses implementation state. You MUST proactively manage context to avoid hitting auto-compact.

### Context Monitoring (MANDATORY)

Monitor context usage and act at these thresholds:

| Context Remaining | Action Required |
|-------------------|-----------------|
| **30%** | CHECKPOINT: Update `.claude/plan.md` with all current state |
| **15%** | FINALIZE: Complete current micro-task, commit work, fully update plan.md |
| **10%** | CLEAR: Request `/clear` and instruct user to re-invoke skill to resume |

**Never let context hit 0%** - auto-compaction loses critical details that plan.md cannot fully capture.

### Checkpoint Protocol

At every checkpoint (30% threshold or after completing a story):

1. **Update `.claude/plan.md`** with:
   - Current story status and what's done vs remaining
   - Exact files modified and their states
   - Any validation results (tests, lint, etc.)
   - Learnings and gotchas discovered
   - Next action to take when resuming

2. **Commit work-in-progress** if anything is uncommitted:
   ```bash
   git add -A && git commit -m "wip: <current story description>"
   ```

3. **Log the checkpoint** in plan.md Progress Log section

### Context Budget Planning

During Phase 1 (Initialize), estimate context budget:

```markdown
## Context Budget
- Estimated stories: 5
- Target context per story: ~15-20%
- Research budget (subagents): separate context
- Current usage: 0%
```

Update this section at each checkpoint. If a story consumes more than 25% context, it's too large - break it down.

### Mandatory Subagent Usage

**ALWAYS** use subagents for these tasks to preserve main context:

| Task Type | Required Subagent |
|-----------|-------------------|
| Codebase exploration/research | `Task` tool with `Explore` agent |
| Architecture planning | `Task` tool with `Plan` agent |
| Pattern discovery | `Task` tool with `Explore` agent |
| Understanding existing code | `Task` tool with `Explore` agent |

**Never** do broad codebase research in the main context. The main context is for:
- Reading/updating plan.md
- Making focused code changes
- Running validation commands
- Committing and managing git state

### Requesting Context Clear

When reaching 10-15% context remaining:

1. Ensure `.claude/plan.md` is fully updated
2. Ensure all work is committed (even WIP)
3. Output to user:
   ```
   Context is at ~X%. I've checkpointed all state to .claude/plan.md.
   Please run `/clear` then re-invoke `/autonomous-coder` to resume.
   ```

### Plan.md Structure for Context Resilience

```markdown
---
task: <original task description>
branch: <feature branch name>
iteration: <current iteration number>
status: in_progress | complete
context_checkpoint: <timestamp of last checkpoint>
---

## Context Budget
- Total stories: X
- Completed: Y
- Current context usage: ~Z%

## Acceptance Criteria
- [ ] Criterion 1
- [x] Criterion 2 (completed)

## Stories
| ID | Story | Priority | Status | Context Used |
|----|-------|----------|--------|--------------|
| 1  | <story> | high | complete | ~18% |
| 2  | <story> | high | in_progress | ~12% (ongoing) |
| 3  | <story> | medium | pending | - |

## Current Story
**ID**: 2
**Description**: <what to implement>
**Approach**: <implementation plan>
**Files**: <files to modify>
**What's Done**: <completed parts of this story>
**What's Remaining**: <remaining parts>
**Next Action**: <exact next step to take when resuming>

## Learnings
- <gotcha discovered in iteration 1>
- <pattern to follow discovered in iteration 2>

## Progress Log
### Iteration 1
- Completed: Story 1
- Learnings: <what was learned>
- Context used: ~18%

### Iteration 2
- In Progress: Story 2
- Checkpoint at: <timestamp>
- Status: <detailed current status>
```

## Validation Tools Reference

### abenv (Python environment)
```bash
abenv --local -- <command>  # Local development
abenv --realm <realm> -- <command>  # With AWS auth
```

### coderabbit (Code review)
```bash
coderabbit review --diff "<diff>"  # Review changes
coderabbit suggest --file <file>   # Get suggestions
```

### Test Commands by Language
- Python: `abenv --local -- pytest <path> --no-migrations --disable-warnings`
- Go: `go test -v ./...` or `bazel test //path/to:target`
- JS: `yarn --cwd <project-root> test`

## Completion Criteria

The autonomous loop completes when ALL of the following are TRUE:

1. All acceptance criteria met
2. All tests passing (with actual output shown)
3. Lint/type checks passing (with actual output shown)
4. Code review clean (coderabbit has no critical issues)
5. PR created and ready for human review

**ONLY THEN** may you output the completion promise:

```
<promise>All tests passing and code review clean</promise>
```

**DO NOT** output this promise tag if:
- Tests are failing or skipped
- Lint errors exist
- Type errors exist
- You haven't actually run validation
- You're just hoping it works

The ralph-loop will feed the prompt back if you try to exit without completing. Trust the loop.

## Important Guidelines

1. **Context is sacred**: Monitor context usage constantly. Checkpoint at 30%, finalize at 15%, clear at 10%. Never hit auto-compact.
2. **Subagents for research**: ALWAYS use Task tool with Explore agent for codebase research. Never pollute main context with exploration.
3. **Right-sized stories**: Each story must fit in ~15-20% of context. If larger, break it down.
4. **Atomic commits**: One logical change per commit. Commit WIP before context clears.
5. **Validate early**: Run tests after each change, not just at the end
6. **Document everything**: Update `.claude/plan.md` at every checkpoint with exact state needed to resume
7. **Trust the loop**: Don't skip validation even if confident

## Resources

- `references/workflow.md`: Detailed execution phases and decision trees
- `assets/plan_template.md`: Template for `.claude/plan.md`
