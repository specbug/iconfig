# Autonomous Coder Workflow Reference

Detailed execution phases, decision trees, and troubleshooting for the Ralph methodology.

## Ralph Loop Integration (MANDATORY)

The autonomous-coder skill REQUIRES the ralph-loop plugin to enforce iteration.

### Starting the Loop

```bash
/ralph-loop "<task description>" --completion-promise "All tests passing and code review clean" --max-iterations 20
```

### How It Works

1. Ralph-loop creates a stop-hook in `.claude/ralph-loop.local.md`
2. When you try to exit/complete, the hook feeds the SAME PROMPT back
3. You see your previous work in files and git history
4. Loop continues until you output `<promise>All tests passing and code review clean</promise>`
5. The promise is ONLY valid when genuinely true

### Iteration Behavior

Each iteration:
1. Check current state (plan.md, git status, git log)
2. Identify what's done vs remaining
3. Continue implementation or fix validation failures
4. Run validation (tests, lint, type check)
5. If passing → output promise tag to exit
6. If failing → loop continues automatically

### DO NOT Lie to Exit

The ralph-loop is designed to prevent premature exit. Even if you feel stuck:
- Do NOT output a false promise
- Do NOT claim tests pass when they don't
- The loop will naturally complete when work is genuinely done
- If truly blocked, ask the user for help rather than lying

## Context Management Decision Tree (CHECK FIRST)

```
What is current context usage?
├─ >70% remaining → Continue normal work
├─ 30-70% remaining → CHECKPOINT
│   ├─ Update .claude/plan.md with full state
│   ├─ Commit any uncommitted work (even WIP)
│   └─ Continue with current story
├─ 15-30% remaining → FINALIZE
│   ├─ Complete current micro-task only
│   ├─ Update .claude/plan.md with exact resume point
│   ├─ Commit all work
│   └─ Assess: can next task fit in remaining context?
│       ├─ YES → Continue carefully
│       └─ NO → Request context clear
└─ <15% remaining → CLEAR NOW
    ├─ Stop current work immediately
    ├─ Commit all changes (wip commit is fine)
    ├─ Update .claude/plan.md with:
    │   - Exact current state
    │   - What's done, what's remaining
    │   - Next action to take
    └─ Tell user: "Run /clear then re-invoke /autonomous-coder"
```

**CRITICAL**: Check context usage before and after every major action.

## Decision Trees

### Task Classification

```
Is this a coding task?
├─ NO → Do not use this skill
└─ YES → Does it require validation/testing?
    ├─ NO (docs, config only) → Do not use this skill
    └─ YES → Use autonomous-coder skill
```

### Story Sizing (Context-Aware)

```
Can this story be completed in ~15-20% of context?
├─ YES → Proceed with implementation
└─ NO → Break down further
    ├─ Identify independent sub-components
    ├─ Create separate stories for each
    ├─ Ensure each story is self-contained
    └─ Target: each story uses ≤20% context
```

### Research Task Handling

```
Do I need to explore/understand the codebase?
├─ YES → MUST use Task tool with Explore agent
│   ├─ Never read multiple files directly in main context
│   ├─ Never grep/glob extensively in main context
│   └─ Subagent results are summarized, saving context
└─ NO (focused change to known file) → Proceed in main context
```

### Validation Failure Handling

```
Validation failed
├─ Lint errors?
│   ├─ Auto-fixable → Run fix command, re-validate
│   └─ Manual fix → Update code, re-validate
├─ Type errors?
│   ├─ Missing types → Add type annotations
│   ├─ Type mismatch → Fix implementation
│   └─ External types → Check stubs or ignore with comment
├─ Test failures?
│   ├─ New test failing → Fix implementation or update test
│   ├─ Existing test failing → Investigate regression
│   └─ Flaky test → Document and consider skipping
└─ Code review issues?
    ├─ Critical → Must fix before proceeding
    ├─ Major → Fix unless blocking progress
    └─ Minor → Fix or document for follow-up
```

## Phase Details

### Phase 1: Initialize - Detailed

1. **Check for existing plan**
   ```bash
   test -f .claude/plan.md && echo "Plan exists" || echo "No plan"
   ```

2. **If resuming**: Read existing plan, determine current state
3. **If new task**: Create plan from requirements

4. **Branch management**
   ```bash
   # Check current branch
   git branch --show-current

   # If on main, create feature branch
   git checkout -b $USER/pr/<feature-name>
   ```

5. **Initial plan structure**
   - Parse requirements into acceptance criteria
   - Break into stories (aim for 3-7 stories)
   - Prioritize: dependencies first, then value

### Phase 2: Plan - Detailed

1. **Story selection**
   - Pick highest priority incomplete story
   - Verify no blocking dependencies
   - Read related code areas

2. **Codebase research**
   - Use Task tool with Explore agent for broad searches
   - Check `*_dev.md` files for patterns
   - Identify files to modify

3. **Implementation approach**
   - Document in plan.md
   - Include specific files and functions
   - Note any risks or unknowns

### Phase 3: Execute - Detailed

**Python implementation pattern:**
```bash
# Create/modify files
# Then verify syntax
abenv --local -- python -m py_compile <file.py>

# Run quick validation
abenv --local -- ruff check <file.py>
```

**Go implementation pattern:**
```bash
# After modifications
go build ./...
go vet ./...
```

**JS implementation pattern:**
```bash
# After modifications
yarn --cwd <project> tsc --noEmit
yarn --cwd <project> lint
```

### Phase 4: Validate - Detailed (MANDATORY - DO NOT SKIP)

**CRITICAL**: You MUST run validation after EVERY code change. The ralph-loop will force you back if you skip this.

**Validation order is important:**

1. **Syntax/Compile** (fast, catches obvious errors)
2. **Lint** (catches style and common issues)
3. **Type check** (catches type errors)
4. **Unit tests** (verifies behavior)
5. **Integration tests** (if applicable)
6. **Code review** (catches design issues)

**Required validation commands (run ALL relevant ones):**

```bash
# Python - ALL THREE required
abenv --local -- ruff check <modified_files>
abenv --local -- mypy <modified_files>  # if typed
abenv --local -- pytest <test_files> --no-migrations --disable-warnings -v

# Go - ALL THREE required
go build ./...
go vet ./...
go test -v ./...

# JS - ALL THREE required
yarn --cwd <path> tsc --noEmit
yarn --cwd <path> lint
yarn --cwd <path> test
```

**You MUST show actual output** - don't just say "tests passed". Copy the terminal output into plan.md and show it in your response.

**Handling large test suites:**
```bash
# Run only affected tests first
pytest <specific_test_file.py> -v

# Then run full suite
pytest <test_dir> --no-migrations --disable-warnings
```

**If validation fails:**
1. Do NOT proceed to commit
2. Do NOT try to exit the loop
3. Fix the issue and re-run validation
4. Repeat until ALL validation passes

### Phase 5: Commit - Detailed

**Commit message format:**
```
<type>: <short description>

<longer description if needed>

- Detail 1
- Detail 2
```

Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`

**Commit best practices:**
- One logical change per commit
- Tests should pass after each commit
- Include relevant issue references

### Phase 6: Iterate - Detailed

**Progress check:**
```markdown
## Stories Checklist
- [x] Story 1: <description>
- [x] Story 2: <description>
- [ ] Story 3: <description> ← current
- [ ] Story 4: <description>
```

**When to continue:**
- Stories remain incomplete
- Acceptance criteria not met
- Tests not passing

**When to complete:**
- All stories done
- All tests passing
- Code review clean

### Phase 7: PR - Detailed

**Pre-PR checklist:**
- [ ] All commits pushed
- [ ] Branch up to date with main
- [ ] Tests passing in CI
- [ ] No merge conflicts

**PR description template:**
```markdown
## Summary
Brief motivation for the change (1-2 sentences)

## Changes
- Change 1
- Change 2
- Change 3

## Test Plan
[x] Unit tests
```bash
$ pytest src/pytests/path/to/test.py
===== 15 passed in 2.3s =====
```

[x] Lint check
```bash
$ ruff check
All checks passed!
```

[ ] Manual verification of <specific behavior>

## Deploy Plan
<deployment steps or "No special deployment needed">
```

## Troubleshooting

### Context Window Running Low (URGENT)

**Do NOT wait until context is exhausted. Act immediately.**

At 30% remaining:
```bash
# 1. Checkpoint to plan.md
# 2. Commit work in progress
git add -A && git commit -m "wip: checkpoint at 30% context"
```

At 15% remaining:
```bash
# 1. Stop exploration, complete only current micro-task
# 2. Full update to plan.md with resume instructions
# 3. Commit everything
git add -A && git commit -m "wip: checkpoint at 15% context - ready to resume"
```

At 10% remaining:
```
Output to user:
"Context at ~10%. Checkpointed to .claude/plan.md.
Please run /clear then re-invoke /autonomous-coder to resume from Story X."
```

**Recovery after unintended compaction:**
1. Read `.claude/plan.md` to recover state
2. Check `git log --oneline -10` for recent commits
3. Check `git status` and `git diff` for uncommitted work
4. Resume from last documented state in plan.md

### Tests Consistently Failing

1. Check if test environment is correct
   ```bash
   abenv --local -- python -c "import sys; print(sys.path)"
   ```

2. Check for missing dependencies
3. Check for database/fixture issues
4. Consider if test needs updating vs code

### Merge Conflicts

1. Update plan.md with current progress
2. Fetch and rebase:
   ```bash
   git fetch origin main
   git rebase origin/main
   ```
3. Resolve conflicts
4. Continue with validation

### coderabbit CLI Issues

If coderabbit review hangs or fails:
1. Check authentication: `coderabbit auth status`
2. Try smaller diff: `git diff --stat` to see size
3. Review manually if CLI unavailable

## Anti-Patterns to Avoid

1. **Giant stories** - Break down if > 500 lines changed
2. **Skipping validation** - Always run tests, even for "small" changes
3. **Ignoring plan.md** - Always update before context might clear
4. **Committing broken code** - Each commit should leave repo in working state
5. **Rushing to PR** - Ensure all validation passes first
