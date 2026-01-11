---
name: ripgrep
description: This skill should be used when the user asks about "ripgrep", "rg command", "fast grep", "search files", "code search", "regex search in files", "find in files", "search codebase", "grep replacement", or needs guidance on file content searching, pattern matching, or recursive text search. Provides command reference, usage patterns, and best practices for ripgrep (rg).
---

# ripgrep (rg) CLI Reference

ripgrep is a line-oriented search tool that recursively searches directories for regex patterns. It respects `.gitignore` rules by default and automatically skips hidden files, directories, and binary files.

## Basic Usage

```bash
# Search for pattern in current directory (recursive)
rg 'pattern'

# Search specific file
rg 'pattern' file.txt

# Search specific directory
rg 'pattern' src/

# Multiple paths
rg 'pattern' src/ tests/ docs/
```

## Essential Flags

| Flag | Short | Description |
|------|-------|-------------|
| `--ignore-case` | `-i` | Case-insensitive search |
| `--smart-case` | `-S` | Case-insensitive unless pattern has uppercase |
| `--word-regexp` | `-w` | Match whole words only |
| `--fixed-strings` | `-F` | Treat pattern as literal string (no regex) |
| `--count` | `-c` | Show count of matches per file |
| `--files-with-matches` | `-l` | Show only filenames with matches |
| `--files-without-match` | `-L` | Show only filenames without matches |
| `--line-number` | `-n` | Show line numbers (default when output is terminal) |
| `--no-line-number` | `-N` | Suppress line numbers |
| `--only-matching` | `-o` | Print only the matched text |
| `--invert-match` | `-v` | Show non-matching lines |
| `--multiline` | `-U` | Enable multiline matching (`.` matches newlines) |

## Context Lines

```bash
# Show 3 lines after each match
rg -A 3 'pattern'

# Show 3 lines before each match
rg -B 3 'pattern'

# Show 3 lines before and after (context)
rg -C 3 'pattern'
```

## File Filtering

### By File Type

```bash
# Search only in Rust files
rg 'pattern' --type rust
rg 'pattern' -trust

# Exclude JavaScript files
rg 'pattern' --type-not js
rg 'pattern' -Tjs

# List all available types
rg --type-list

# Define custom type
rg --type-add 'web:*.{html,css,js}' -tweb 'pattern'
```

Common built-in types: `py`, `js`, `ts`, `rust`, `go`, `java`, `c`, `cpp`, `html`, `css`, `json`, `yaml`, `md`, `sh`

### By Glob Pattern

```bash
# Include only .toml files
rg 'pattern' -g '*.toml'

# Include files in specific directory
rg 'pattern' -g 'src/**/*.rs'

# Exclude files (prefix with !)
rg 'pattern' -g '!*.min.js'

# Multiple globs
rg 'pattern' -g '*.rs' -g '*.toml'
```

## Automatic Filtering Control

ripgrep automatically ignores:
1. Files matching `.gitignore`, `.ignore`, `.rgignore` patterns
2. Hidden files and directories
3. Binary files

```bash
# Disable .gitignore filtering
rg --no-ignore 'pattern'

# Search hidden files
rg --hidden 'pattern'
rg -. 'pattern'

# Search binary files as text
rg --text 'pattern'
rg -a 'pattern'

# Shorthand for disabling filters
rg -u 'pattern'    # --no-ignore
rg -uu 'pattern'   # --no-ignore --hidden
rg -uuu 'pattern'  # --no-ignore --hidden --text
```

## Regex Patterns

ripgrep uses Rust regex syntax by default.

```bash
# Word characters followed by digits
rg '\w+\d+'

# Start/end of line anchors
rg '^start'
rg 'end$'

# Character classes
rg '[A-Z][a-z]+'

# Alternation
rg 'foo|bar'

# Quantifiers
rg 'colou?r'       # 0 or 1
rg 'a+'            # 1 or more
rg 'a*'            # 0 or more
rg 'a{2,4}'        # 2 to 4 times

# Non-greedy matching
rg 'a+?'

# Lookahead/lookbehind (requires PCRE2)
rg -P '(?<=prefix)\w+'    # Lookbehind
rg -P '\w+(?=suffix)'     # Lookahead
```

### PCRE2 Mode

Enable PCRE2 for advanced regex features:

```bash
# Enable PCRE2
rg -P 'pattern'
rg --pcre2 'pattern'

# Auto-detect when PCRE2 is needed
rg --engine auto 'pattern'
```

## Multiline Search

```bash
# Basic multiline (dot matches newline)
rg -U 'start.*end'

# Match across lines with PCRE2
rg -UP 'function\s+\w+\s*\([^)]*\)\s*\{'
```

## Replacements (Output Only)

ripgrep never modifies files. The `--replace` flag transforms output only.

```bash
# Simple replacement
rg 'old' -r 'new'

# With capture groups
rg '(\w+)@(\w+)' -r '$2:$1'

# Named capture groups
rg '(?P<user>\w+)@(?P<domain>\w+)' -r '$domain:$user'
```

## Output Formats

```bash
# JSON output (for parsing)
rg --json 'pattern'

# Null-separated filenames (for xargs -0)
rg -l --null 'pattern'

# Show only matching files
rg -l 'pattern'

# Show files that would be searched
rg --files

# Show files matching glob
rg --files -g '*.rs'
```

## Performance Options

```bash
# Limit search depth
rg --max-depth 3 'pattern'

# Limit results
rg --max-count 5 'pattern'    # Per file
rg 'pattern' | head -n 100    # Total

# Disable memory maps (for consistency)
rg --no-mmap 'pattern'

# Sort results by path
rg --sort path 'pattern'
```

## Common Patterns

### Find function definitions

```bash
# Rust
rg '^(pub\s+)?(async\s+)?fn\s+\w+'

# Python
rg '^def \w+|^class \w+'

# JavaScript/TypeScript
rg '(function|const|let|var)\s+\w+\s*='
```

### Find TODO/FIXME comments

```bash
rg 'TODO|FIXME|XXX|HACK' -g '!*.min.*'
```

### Find imports/requires

```bash
# Python
rg '^(import|from)\s+\w+'

# JavaScript
rg "^(import|require\()"

# Go
rg '^import\s+'
```

### Search specific patterns

```bash
# IP addresses (approximate)
rg '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}'

# Email addresses (simple)
rg '\w+@\w+\.\w+'

# URLs
rg 'https?://[^\s]+'
```

## Configuration File

Set default options via `RIPGREP_CONFIG_PATH`:

```bash
export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"
```

Example `~/.ripgreprc`:

```
--smart-case
--hidden
--glob=!.git/*
--max-columns=150
--max-columns-preview
```

## Debugging

```bash
# Show what files would be searched and why others are ignored
rg --debug 'pattern'

# Disable config file
rg --no-config 'pattern'
```

## Key Differences from grep

| Feature | ripgrep | GNU grep |
|---------|---------|----------|
| Recursive by default | Yes | No (`-r` required) |
| Respects .gitignore | Yes | No |
| Skips binary files | Yes | No |
| Unicode by default | Yes | Depends on locale |
| Parallel search | Yes | No |
| Memory-mapped files | Yes | No |

## Reference

For advanced features, see:
- [references/advanced.md](references/advanced.md) - Preprocessors, encoding, binary handling
