---
name: git-spice
description: >-
  This skill should be used when the user asks about "stacked branches",
  "git-spice", "gs command", "stacked PRs", "stacked pull requests",
  "stacked merge requests", "branch stacks", "restack branches",
  "submit stack", "gs branch", "gs stack", "gs upstack", "gs downstack",
  "gs repo sync", or needs help managing multiple dependent branches.
version: 0.1.0
---

# git-spice CLI

git-spice (`gs`) is a CLI tool for managing stacked Git branches.
It tracks relationships between branches, enables easy navigation,
and creates stacked Pull Requests on GitHub or Merge Requests on GitLab.

## Key Concepts

- **Stack**: Collection of branches stacked on top of each other
- **Trunk**: The default branch (main/master) with no base
- **Upstack**: Branches above the current branch
- **Downstack**: Branches below the current branch (not including trunk)
- **Restacking**: Rebasing a branch onto its base to maintain linear history

## Command Reference

### Repository Commands (`gs repo` / `gs r`)

| Command | Shorthand | Description |
|---------|-----------|-------------|
| `gs repo init` | `gs ri` | Initialize git-spice in a repository |
| `gs repo sync` | `gs rs` | Pull latest changes, delete merged branches |
| `gs repo restack` | `gs rr` | Restack all tracked branches |

### Branch Commands (`gs branch` / `gs b`)

| Command | Shorthand | Description |
|---------|-----------|-------------|
| `gs branch create <name>` | `gs bc` | Create and track a new stacked branch |
| `gs branch track` | `gs bt` | Track an existing branch |
| `gs branch untrack` | `gs but` | Stop tracking a branch (keep in Git) |
| `gs branch checkout <name>` | `gs bco` | Check out a branch (interactive if no name) |
| `gs branch delete <name>` | `gs bd` | Delete a tracked branch |
| `gs branch rename <new>` | `gs brn` | Rename the current branch |
| `gs branch submit` | `gs bs` | Submit current branch as a CR |
| `gs branch restack` | `gs br` | Restack current branch onto its base |
| `gs branch edit` | `gs be` | Interactive rebase of branch commits |
| `gs branch squash` | `gs bsq` | Squash all commits in current branch |
| `gs branch split` | `gs bsp` | Split branch into multiple branches |
| `gs branch onto <base>` | `gs bo` | Move branch to a different base |
| `gs branch fold` | `gs bf` | Fold branch into its base |

### Stack Commands (`gs stack` / `gs s`)

| Command | Shorthand | Description |
|---------|-----------|-------------|
| `gs stack submit` | `gs ss` | Submit all branches in the stack |
| `gs stack restack` | `gs sr` | Restack all branches in the stack |
| `gs stack edit` | `gs se` | Edit order of branches in the stack |
| `gs stack delete` | `gs sd` | Delete all branches in the stack |

### Upstack Commands (`gs upstack` / `gs us`)

| Command | Shorthand | Description |
|---------|-----------|-------------|
| `gs upstack submit` | `gs uss` | Submit current branch and those above |
| `gs upstack restack` | `gs usr` | Restack current branch and upstack |
| `gs upstack onto <base>` | `gs uso` | Move branch and upstack to new base |
| `gs upstack delete` | `gs usd` | Delete all branches above current |

### Downstack Commands (`gs downstack` / `gs ds`)

| Command | Shorthand | Description |
|---------|-----------|-------------|
| `gs downstack submit` | `gs dss` | Submit current branch and those below |
| `gs downstack track` | `gs dst` | Track multiple branches at once |
| `gs downstack edit` | `gs dse` | Edit order of downstack branches |

### Commit Commands (`gs commit` / `gs c`)

| Command | Shorthand | Description |
|---------|-----------|-------------|
| `gs commit create` | `gs cc` | Commit and restack upstack branches |
| `gs commit amend` | `gs ca` | Amend last commit and restack |
| `gs commit split` | `gs csp` | Split last commit into two |
| `gs commit fixup` | `gs cf` | Create a fixup commit |
| `gs commit pick` | `gs cp` | Cherry-pick commits into branch |

### Navigation Commands

| Command | Shorthand | Description |
|---------|-----------|-------------|
| `gs up` | `gs u` | Move up one branch in the stack |
| `gs down` | `gs d` | Move down one branch in the stack |
| `gs top` | `gs U` | Move to top of stack |
| `gs bottom` | `gs D` | Move to bottom of stack |
| `gs trunk` | - | Move to trunk branch |

### Log Commands (`gs log` / `gs l`)

| Command | Shorthand | Description |
|---------|-----------|-------------|
| `gs log short` | `gs ls` | Show branches as a tree |
| `gs log long` | `gs ll` | Show branches with commits |

Add `--all` to show all stacks, not just the current one.
Add `--json` for machine-readable output.

### Authentication (`gs auth`)

| Command | Description |
|---------|-------------|
| `gs auth login` | Authenticate with GitHub/GitLab |
| `gs auth logout` | Log out from the service |
| `gs auth status` | Show authentication status |

### Rebase Commands (`gs rebase` / `gs rb`)

| Command | Shorthand | Description |
|---------|-----------|-------------|
| `gs rebase continue` | `gs rbc` | Continue interrupted rebase |
| `gs rebase abort` | `gs rba` | Abort the current rebase |

## Common Workflows

### Create a New Stack

```bash
# Start from trunk
gs trunk

# Create first feature branch
git add file.txt
gs branch create feat1

# Stack another branch on top
git add another.txt
gs branch create feat2
```

### Submit a Stack for Review

```bash
# Submit entire stack
gs stack submit

# Or submit with auto-filled PR info
gs stack submit --fill
```

### Modify Mid-Stack and Update

```bash
# Navigate to the branch to modify
gs down  # or: gs bco feat1

# Make changes and commit
git add file.txt
gs commit create -m "fix typo"

# Submit updates to all CRs
gs stack submit
```

### Sync After Merges

```bash
# Pull latest, delete merged branches, restack remaining
gs repo sync
```

### Move a Branch to Different Base

```bash
# Move current branch and upstack to main
gs upstack onto main

# Move only current branch (leave upstack in place)
gs branch onto main
```

### Split a Branch

```bash
# Interactively split current branch at commit boundaries
gs branch split
```

## Common Flags

- `--fill` / `-c`: Auto-fill CR info from commits
- `--draft` / `--no-draft`: Set CR draft status
- `--force`: Force push (override safety checks)
- `--update-only`: Only update existing CRs, don't create new ones
- `-n` / `--dry-run`: Show what would happen without doing it
- `--no-prompt`: Disable interactive prompts

## Configuration

Set options with `git config`:

```bash
# Create branches without committing by default
git config spice.branchCreate.commit false

# Add prefix to all created branches
git config spice.branchCreate.prefix "user/"

# Create CRs as drafts by default
git config spice.submit.draft true

# Open browser when CR is created
git config spice.submit.web created

# Add default labels to all CRs
git config spice.submit.label "needs-review"

# Add default reviewers
git config spice.submit.reviewers "alice,myorg/team"
```

## Tips

- Use `--help` on any command to see its shorthand
- Interactive prompts provide fuzzy search for branch selection
- Navigation commands accept `-n` to print target without switching
- Use `gs bco` without arguments for an interactive branch picker
