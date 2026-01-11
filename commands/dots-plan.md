---
description: Plan complex work with collaborative AI debate, create dot tasks with dependencies
argument-hint: [optional focus area]
---

# Planning Dot Tasks

Review the conversation history above to identify work that needs planning. Extract requirements, decisions, and context discussed—these inform the dot tasks you create. If the user provided additional instructions below, incorporate those as well.

This is a two-phase process: discovery first, then planning with collaborative debate.

## Phase 1: Discovery

Gather context from the conversation history and find verification commands.

### Step 1: Verification Commands
Run a focused Explore query to find exact development commands:
```
Find the ACTUAL commands used in this project for verification. Search in order:
1. mise.toml / .mise.toml (mise task runner - https://github.com/jdx/mise)
2. package.json scripts / pyproject.toml / Makefile / Justfile
3. .github/workflows (CI jobs are authoritative)
4. docs/CONTRIBUTING.md or README.md

For each category, report the EXACT command string:
- Linting/formatting (e.g., `mise run lint`, `go fmt ./...`)
- Static analysis / type checking (e.g., `mise run check`, `staticcheck ./...`, `golangci-lint run`)
- Unit tests (e.g., `mise run test`, `go test ./...`)
- Scoped E2E tests - run specific tests (e.g., `mise run test:e2e -- -run TestAuth`, `go test ./e2e/... -run TestAuth`)
- Full E2E tests - run entire suite (e.g., `mise run test:e2e`, `go test ./e2e/...`)

Output format: "CATEGORY: [exact command]"
Stop searching a category once you find an authoritative source.
```

### Step 2: Discovery Synthesis
Consolidate findings from conversation history into planning input:
- **Architecture overview**: Patterns, conventions, and constraints discussed
- **Testing setup**: Where tests live, how to run them, what coverage exists
- **Verification commands**: From Step 1
- **Known risks**: Edge cases and caveats identified

This synthesis becomes the input for Phase 2.

## Phase 2: Planning with Collaborative Debate

Use multi-round refinement for thorough planning.

### Guiding Principles: Speed-of-Light Implementation

**Treat planning as a minimization problem.** The goal is not to design a comprehensive solution—it's to find the smallest, fastest path to the desired outcome.

- **Minimize changes**: What is the absolute minimum number of lines, files, and touch points needed? Every additional change is a potential bug, a review burden, and merge conflict risk.
- **Minimize complexity**: Prefer boring, obvious solutions over clever ones. If two approaches work, choose the one a junior developer could understand in 5 minutes.
- **Minimize scope**: Ruthlessly cut anything that isn't strictly required. "Nice to have" belongs in a separate future task, not this plan.
- **Minimize risk**: Favor incremental changes over big-bang rewrites. Ship something small that works over something ambitious that might not.

**Ask at every decision point**: "Is there a simpler way?" If the answer is yes, take it.

### Step 1: Initial Plan
Use the Plan subagent with **model: "opus"** to design the minimum viable implementation based on discovery synthesis. The plan should answer: "What is the smallest change that achieves the goal?"

### Step 2: Collaborative Debate (1-5 rounds, until feedback converges)
Claude (Opus) and Codex (gpt-5.2-codex) debate back-and-forth to refine the plan. The number of rounds depends on complexity and whether feedback converges:

- **Simple/straightforward plans**: 1 round may suffice if both models agree
- **Moderate complexity**: 2-3 rounds typical
- **Complex or contentious plans**: Up to 5 rounds if feedback doesn't converge

**Round 1 - Dual Critique**:
- **Claude (Opus)**: Review the plan through a minimization lens. For each concern: (1) Is this change actually necessary? (2) Is there a simpler alternative? (3) What can be cut or deferred? Also flag genuine gaps or risks.
- **Codex**: Use `mcp__codex-cli__codex` with model "gpt-5.2-codex":
  ```
  prompt: "Review this implementation plan with a minimization mindset: [plan]. The goal is the smallest, simplest path to the outcome. For each part of the plan: (1) Is this necessary or can it be cut? (2) Is there a simpler approach? (3) What's the minimum viable version? Also list any genuine gaps or risks, with concrete mitigations."
  ```
- Synthesize both critiques. Prioritize simplification opportunities alongside risk fixes.
- **Exit condition**: If both models agree the plan is minimal and sound, proceed to task creation.

**Round 2+ - Address & Counter** (repeat until convergence or Round 5):
- **Claude (Opus)**: Propose revisions that make the plan simpler, not more complex. For each concern: accept and simplify, reject with rationale, or defer to a future task. Resist adding complexity to "fix" problems.
- **Codex**: Use `mcp__codex-cli__codex` with model "gpt-5.2-codex":
  ```
  prompt: "Claude proposes these revisions: [revisions]. Evaluate with a bias toward simplicity: (1) Does this revision add or remove complexity? (2) Is there an even simpler fix? (3) Should this concern be deferred rather than addressed now? Flag any revision that makes the plan bigger rather than smaller."
  ```
- Integrate valid counterpoints. If a fix adds more complexity than the problem warrants, defer it.
- **Exit condition**: Feedback converges (plan is minimal, both models agree on approach).

**Final Round - Consensus Check** (when exiting):
- **Claude (Opus)**: Present the refined plan. Confirm it represents the minimum viable implementation. List what was intentionally deferred.
- **Codex**: Use `mcp__codex-cli__codex` with model "gpt-5.2-codex":
  ```
  prompt: "Final minimization check: [plan]. Verify: (1) Is this the smallest possible implementation? (2) Can anything else be cut or deferred? (3) Are there any 'nice to haves' hiding as requirements? (4) Is the testing strategy proportional (not over-tested)? Approve only if the plan is truly minimal."
  ```
- If consensus: Proceed to task creation.
- If minor disagreement: Choose the simpler option, defer the rest.
- If still unresolved after Round 5: Choose the approach with fewer moving parts. Document what was deferred and why.

### Quality Gate
Before creating tasks, confirm:
- [ ] All discovered edge cases addressed or explicitly deferred with rationale
- [ ] Error paths defined (what happens when X fails?)
- [ ] Testing strategy covers new code
- [ ] Trade-offs documented with reasoning

### Step 3: Create Tasks

Create dot tasks using the dots skill. Each task must:
1. Have clear acceptance criteria (what success looks like)
2. Be scoped to complete in one session
3. End with verification notes using **discovered commands** (not generic phrases):
   ```
   ## Verification
   - [ ] `[discovered lint command]` passes
   - [ ] `[discovered static analysis command]` passes
   - [ ] `[discovered test command]` passes
   - [ ] `[discovered scoped e2e command]` passes (if applicable)
   ```
   Use exact commands from Phase 1 discovery. Omit categories if no command exists.
4. Include note: "If implementation reveals new issues, create separate dot tasks for investigation"

Create tasks using:
```bash
dot add "Task title" -d "Description with acceptance criteria and verification steps"
```

### Step 4: Final Verification Task

After creating all implementation tasks, create one final dot task to run the full test suite:

1. **Create the task**:
   ```bash
   dot add "Run full E2E/integration test suite" -d "Verify all changes work together by running the complete test suite. Include the discovered full E2E command. Acceptance criteria: All tests pass, no regressions introduced. If any tests fail, create new tasks for each failure before completing this task."
   ```

2. **Set up dependencies**:
   Use `dot update <final-task-id> -a <implementation-task-id>` for EACH implementation task.
   This ensures the final verification runs only after all implementation work is complete.

Example:
```bash
# If implementation tasks are a1b2c3d, e4f5g6h, i7j8k9l and final is m0n1o2p:
dot update m0n1o2p -a a1b2c3d
dot update m0n1o2p -a e4f5g6h
dot update m0n1o2p -a i7j8k9l
```

### Step 5: Create Parent Tasks (Epics)

**IMPORTANT**: Every planned effort MUST have a parent task, even simple single-task work. Workflow automation depends on parent task completion tracking. A simple task = one parent with one child under it.

**Goal**: Create the smallest shippable units of work. Prefer many small parent tasks over few large ones.

#### The Smallest Shippable Unit Test
A parent task is the right size when:
- Removing any child would make it unshippable
- Adding any child would make it do two things instead of one
- You can describe what it ships in one sentence without "and"

#### Decomposition Checklist
Before finalizing parent tasks, ask these questions:

1. **File overlap test**: Do any two tasks modify the same files?
   - If YES and they're in different parents → merge parents or resequence
   - If YES and parent is large → they belong together, but look for other splits

2. **Ship independently test**: Can this parent be merged to main without the others?
   - If NO → it's not self-contained, find the true boundary

3. **Value test**: Does this parent deliver user-visible value or enable future work?
   - If NO → it might be too granular, consider merging with dependent parent

4. **Parallel work test**: Could two developers work on different parents simultaneously without conflicts?
   - If NO → file overlap exists, resequence or merge

#### Split Signals (create separate parents when you see these)
- Different subsystems (API vs UI vs database)
- Different risk profiles (safe refactor vs risky behavior change)
- Natural phases (setup/infrastructure → core feature → polish)
- Optional enhancements vs core functionality

#### Anti-patterns to Avoid
- ❌ One mega-parent containing all work
- ❌ Parents that "prepare" for other parents without delivering value
- ❌ Splitting by arbitrary task count rather than logical boundaries
- ❌ Parents where tasks have no dependency relationship

For each parent task:

```bash
# Create parent task with high priority
dot add "[Parent task name]" -p 1 -d "$(cat <<'EOF'
# Overview
[Brief description of this parent task's scope]

# Why This Is One Unit
[Explain the boundary: what makes this atomic and self-contained?
Why can't it be split further? Why doesn't it need other parents to ship?]

# Implementation Tasks
- [task-id]: [task title]
- [task-id]: [task title]
- [task-id]: Run verification for this parent

# Files Modified
[List primary files this parent touches—used for conflict detection]

# Verification Commands
- Lint: `[discovered lint command]`
- Static analysis: `[discovered static analysis command]`
- Tests: `[discovered test command]`
- Scoped E2E: `[discovered scoped e2e command]`
- Full E2E: `[discovered full e2e command]`

# Success Criteria
[What "done" looks like for this parent task]
EOF
)"
```

Link child tasks to their parent:
```bash
# When creating child tasks, use -P to set parent
dot add "Child task title" -P <parent-task-id> -d "Description..."

# Or update existing tasks to add parent
dot update <child-task-id> -P <parent-task-id>
```

Check progress: `dot tree`

## Handling Failures

When discovery or planning reveals blocking issues:
1. Create a P0 meta task titled: "Create plan for [blocker-topic]"
   ```bash
   dot add "Create plan for [blocker-topic]" -p 0 -d "Description of what was blocking and why it matters. Instruction to use Explore subagent for discovery. Instruction to use Plan subagent to design fix. Instruction to create implementation dot tasks via dots skill."
   ```
2. Any implementation tasks spawned from meta tasks are also P0

$ARGUMENTS
