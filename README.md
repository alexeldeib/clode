# clode

Personal productivity plugin for Claude Code with task management, coding practices, and example scaffolds for building custom hooks, commands, and agents.

## Features

- **Skills**: Dots task management, coding practices guidance
- **Commands**: `/clode:status` - show plugin/project status
- **Agents**: skill-creator - explore projects and generate skills
- **Hooks**: Example scaffolds for PreToolUse, PermissionRequest, Notification, Stop events

## Installation

```bash
# Local development
claude --plugin-dir /path/to/clode

# Or copy to your .claude-plugin directory
cp -r clode ~/.claude-plugin/
```

## Components

### Skills

- **dots** - Task management using the dots CLI
- **coding-practices** - Coding best practices (scaffold)

### Commands

- `/clode:status` - Display plugin and project status information

### Agents

- **skill-creator** - Explores current project, discovers CLIs/commands, creates skills

### Hooks

Example hook configurations for:
- PreToolUse (with AskUserQuestion matcher)
- PermissionRequest
- Notification
- Stop

## Development

This plugin serves as both a productivity tool and a template for building your own plugins.

## License

MIT
