---
name: status
description: Show plugin and project status information
argument-hint: "[--verbose]"
allowed-tools: ["Read", "Bash", "Glob"]
---

# Status Command

Display status information about the clode plugin and current project.

## Execution Steps

1. **Check plugin installation**
   - Verify plugin files exist at expected locations
   - Report any missing components

2. **List available components**
   - Skills: List skills in `skills/` directory
   - Commands: List commands in `commands/` directory
   - Agents: List agents in `agents/` directory
   - Hooks: Check if `hooks/hooks.json` exists and is valid

3. **Project context** (if applicable)
   - Current working directory
   - Git status (if git repo)
   - Any `.dots/` task tracking present

4. **Display summary**
   Format output as a clean status report:
   ```
   clode plugin status
   ==================

   Components:
   - Skills: [count] loaded
   - Commands: [count] available
   - Agents: [count] configured
   - Hooks: [status]

   Project:
   - Directory: [cwd]
   - Git: [status]
   - Tasks: [dots status if present]
   ```

## Arguments

- `--verbose` or `-v`: Show detailed information about each component

## Tips

- Run this command to verify plugin installation
- Use `--verbose` to debug component loading issues
- Check hooks configuration if automation isn't working
