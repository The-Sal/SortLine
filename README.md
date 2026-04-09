# SortLine

A fast code linter for Python, Rust and Swift to do things. Started sortline lines now does some more things.

## Features
- **Multi-language support**: Python, Swift, and Rust
- **Blazing fast**: See below
- **Smart import detection**: Recognizes language-specific import patterns
- **Multi-line aware**: Skips multi-line imports (parentheses, braces)
- **Flexible modes**: Sort imports only or sort all lines by length

## Performance

Benchmarks on combined CPython + Zed + Apache Airflow (~6M lines across 18k+ files):

**Sorting imports** (Python files, excluding tests):
- Sorted **2,285,384 lines** across **8,673 files** in **0.925s**
- ~2.5M lines per second

**Sorting imports** (Rust files, excluding tests):
- Sorted **1,272,179 lines** across **1,764 files** in **0.514s**
- ~2.5M lines per second

**Making Rust functions public** (`--rust:pub`):
- Processed **1,272,179 lines** across **1,764 files** in **1.427s**
- ~890k lines per second

## Installation
### Requirements
- Swift 6.2+
- macOS 13+ (or Linux with Swift toolchain)
### From Source

```bash
swift build -c release
cp .build/release/SortLine /usr/local/bin/sortline
```

Or use the Zed task:
```bash
swift build -c release && ./.build/release/SortLine && ln -sf $(pwd)/.build/release/SortLine /usr/local/bin/sortline
```

## Usage
### Basic Usage

Sort imports in a file:
```bash
sortline <file>
```

Sort multiple files:
```bash
sortline file1.py file2.py file3.py
```

Process entire directory:
```bash
find . -name "*.py" -exec sortline {} +
```

### Language Support

SortLine automatically detects file types and applies the appropriate import patterns:

| Language | Extensions | Import Patterns |
|----------|------------|-----------------|
| Python | `.py` | `import`, `from` |
| Swift | `.swift` | `import` |
| Rust | `.rs` | `use`, `mod` |

### Options

| Flag | Description |
|------|-------------|
| `-h` | Show help message |
| `--verbose` | Print progress information |
| `--all-types` | Sort **all** lines by length (not just imports) |
| `--rust:pub` or `-rpub` | Convert Rust functions to `pub(crate)` |
| `--cli-path` | Print the CLI executable path |

### Examples

**Verbose mode** (see what's being processed):
```bash
sortline --verbose main.py utils.py
# [System] Detected --verbose
# [System] Sorting: main.py...
# [System] Sorting: utils.py...
# [System] Sorted 245 lines, across 2 files
# [System] Done
```

**Sort all lines** (not just imports):
```bash
sortline --all-types myfile.txt
```

**Make Rust functions public**:
```bash
sortline --rust:pub lib.rs
# or
sortline -rpub src/*.rs
```

**Combined with find** (recommended for projects):
```bash
# Sort all Python imports in project
find . -name "*.py" -type f -exec sortline {} +

# Sort all Swift imports
find . -name "*.swift" -type f -exec sortline {} +

# Verbose mode for entire project
find . -name "*.py" -type f -exec sortline --verbose {} +
```

## Version

**1.4.5**
