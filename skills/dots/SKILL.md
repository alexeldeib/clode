---
name: dots
description: This skill should be used when the user mentions "dots", "dot", "tasks", "task", "todo", "issue", "track", "plan", "breakdown", or asks about task management. Provides guidance for using the dots CLI task tracker.
version: 0.1.0
---

# Dots Task Management

Manages tasks using dots - a fast, minimal CLI task tracker that stores tasks as plain markdown files with YAML frontmatter in `.dots/`. Zero dependencies, git-friendly, perfect for AI agent workflows.

## Quick Reference

### Essential Commands

| Command | Purpose | Example |
|---------|---------|---------|
| `dot init` | Initialize `.dots/` directory | `dot init` |
| `dot add "title"` | Create new task | `dot add "Fix login bug"` |
| `dot ls` | List open/active tasks | `dot ls` |
| `dot on <id>` | Mark task as active | `dot on a1b2c3d` |
| `dot off <id>` | Complete and archive task | `dot off a1b2c3d` |
| `dot ready` | Show unblocked tasks | `dot ready` |
| `dot tree` | Show task hierarchy | `dot tree` |
| `dot show <id>` | Display task details | `dot show a1b2c3d` |
| `dot find "query"` | Search tasks | `dot find "auth"` |
| `dot rm <id>` | Delete task permanently | `dot rm a1b2c3d` |

### Task Creation Options

```bash
# Basic task
dot add "Fix the login bug"

# With priority (0=critical, 1=high, 2=normal, 3=low, 4=backlog)
dot add "Critical security fix" -p 0

# With description
dot add "Refactor auth" -d "Move JWT validation to middleware"

# As child of parent task
dot add "Write unit tests" -P parent-task-id

# Blocked by another task (dependency)
dot add "Deploy to prod" -a blocking-task-id

# Quick add (shorthand)
dot "Quick task title"
```

### Task Status Flow

```
open -> active -> done (archived)
```

- **open**: Created, not started
- **active**: Currently being worked on
- **done**: Completed, moved to `.dots/archive/`

### ID Format

IDs use format: `{prefix}-{slug}-{hex}` (e.g., `dots-fix-user-auth-a3f2b1c8`)

Commands accept short prefixes:
```bash
dot on a3f2b1    # Matches dots-fix-user-auth-a3f2b1c8
dot show a3f     # Error if ambiguous
```

## Workflow Patterns

### Planning a Feature

```bash
# Create parent task
dot add "Implement user authentication" -p 1
# Output: dots-impl-user-auth-a1b2c3d4

# Add subtasks
dot add "Design database schema" -P a1b2c3d4
dot add "Create API endpoints" -P a1b2c3d4 -a schema-task-id
dot add "Build login UI" -P a1b2c3d4 -a api-task-id
dot add "Write integration tests" -P a1b2c3d4 -a ui-task-id

# View hierarchy
dot tree
```

### Daily Workflow

```bash
# Start of day: see what's ready
dot ready

# Pick a task and start working
dot on a1b2c3d

# Check active tasks
dot ls --status active

# Complete task with reason
dot off a1b2c3d -r "Fixed in commit abc123"
```

### Managing Dependencies

```bash
# Add dependency after creation
dot update <task-id> -a <blocking-task-id>

# View task to see what's blocking it
dot show <task-id>
```

## Claude Code Integration

dots has built-in hooks for seamless Claude Code integration.

### Hook Configuration

Add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [{"type": "command", "command": "dot hook session"}]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "TodoWrite",
        "hooks": [{"type": "command", "command": "dot hook sync"}]
      }
    ]
  }
}
```

### What Hooks Do

- **SessionStart**: Shows active and ready tasks at conversation start
- **PostToolUse (TodoWrite)**: Syncs Claude's TodoWrite items to dots
  - Creates new dots for new todos
  - Marks dots as done when todos complete
  - Maintains mapping in `.dots/todo-mapping.json`

## Storage Format

Tasks stored as markdown with YAML frontmatter:

```
.dots/
  task-id.md              # Root task
  parent-id/              # Parent with children
    parent-id.md          # Parent task
    child-id.md           # Child task
  archive/                # Completed tasks
  config                  # Project prefix
  todo-mapping.json       # TodoWrite sync state
```

### File Format

```markdown
---
title: Fix the bug
status: open
priority: 2
issue-type: task
created-at: 2024-12-24T10:30:00Z
blocks:
  - other-task-id
---

Description as markdown body here.
```

## Tips

- Use short ID prefixes for speed (first 7 chars usually unique)
- Run `dot slugify` to add readable slugs to existing IDs
- Archive keeps completed tasks accessible via `dot ls --status done`
- Use `dot purge` to permanently delete all archived tasks
- Tasks are git-friendly - commit `.dots/` to track project history
