# Advanced ripgrep Features

## Preprocessors

Transform file contents before searching using `--pre`:

```bash
# Create a preprocessor script
cat > ~/bin/pre-rg << 'EOF'
#!/bin/sh
case "$1" in
*.pdf)
  if [ -s "$1" ]; then
    exec pdftotext - -
  else
    exec cat
  fi
  ;;
*)
  exec cat
  ;;
esac
EOF
chmod +x ~/bin/pre-rg

# Use the preprocessor
rg --pre ~/bin/pre-rg 'pattern' document.pdf

# Limit preprocessor to specific files (performance)
rg --pre ~/bin/pre-rg --pre-glob '*.pdf' 'pattern'
```

## File Encoding

```bash
# Auto-detect encoding (default, handles UTF-16 BOM)
rg -E auto 'pattern'

# Specify encoding
rg -E utf-16 'pattern'
rg -E latin1 'pattern'

# Disable encoding detection (raw bytes)
rg -E none 'pattern'

# Search raw UTF-16
rg '(?-u)\(\x045\x04@\x04' -E none -a file
```

Supported encodings: UTF-8, UTF-16, latin1, GBK, EUC-JP, Shift_JIS, and more from the Encoding Standard.

## Binary File Handling

ripgrep operates in three binary modes:

### Default Mode
Stops searching when NUL byte found (for recursive directory traversal):
```bash
rg 'pattern'
```

### Binary Mode
Continues searching but stops output on first match:
```bash
rg --binary 'pattern'
```

### Text Mode
Treat all files as text:
```bash
rg -a 'pattern'
rg --text 'pattern'
```

## Compressed Files

```bash
# Search compressed files
rg -z 'pattern' archive.gz
rg --search-zip 'pattern' *.tar.gz

# Supported formats: gzip, bzip2, lzma, xz, lz4, brotli, zstd
```

## Symbolic Links

```bash
# Follow symlinks during directory traversal
rg -L 'pattern'
rg --follow 'pattern'
```

## Output Column Control

```bash
# Limit column width
rg -M 150 'pattern'
rg --max-columns 150 'pattern'

# Show preview of truncated lines
rg --max-columns 150 --max-columns-preview 'pattern'

# Show column number of match
rg --column 'pattern'
```

## Sorting and Ordering

```bash
# Sort by file path
rg --sort path 'pattern'

# Sort by modification time
rg --sort modified 'pattern'

# Reverse sort
rg --sortr path 'pattern'
```

Note: Sorting disables parallelism.

## Statistics

```bash
# Show search statistics
rg --stats 'pattern'
```

## Passthrough Mode

Print all lines, highlighting matches:

```bash
rg --passthru 'pattern' file.txt
```

## Count Modes

```bash
# Count matching lines per file
rg -c 'pattern'

# Count all matches (not just lines)
rg --count-matches 'pattern'
```

## Null Data Mode

For files with NUL-separated records instead of newlines:

```bash
rg --null-data 'pattern'
```

## Color Control

```bash
# Force colors (even when piping)
rg --color always 'pattern' | less -R

# Disable colors
rg --color never 'pattern'

# Customize colors
rg --colors 'match:fg:red' --colors 'match:style:bold' 'pattern'
```

Available color specs: `path`, `line`, `column`, `match`

## Hyperlinks

```bash
# Enable hyperlinks in terminal output (clickable paths)
rg --hyperlink-format default 'pattern'
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `RIPGREP_CONFIG_PATH` | Path to config file |
| `NO_COLOR` | Disable color output |

## Performance Tips

1. Use `--pre-glob` with `--pre` to limit preprocessor invocations
2. Use `--max-depth` to limit directory depth
3. Use `-t type` instead of `-g '*.ext'` when possible (faster)
4. Use `--no-mmap` for consistent behavior across platforms
5. Specific paths are faster than recursive search
6. `-F` (fixed strings) is faster than regex for literal patterns
