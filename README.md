# SortLine

A high-performance CLI tool for sorting Python imports by length. Written in Swift for maximum speed and efficiency.

## Performance

On a full Python project + venv (916k+ lines across 6984 files):
- **2.58 seconds** total execution time (including find command overhead)
- Processes ~354k lines per second

## Installation

### From Source

Requirements: Swift 6 (macOS, Linux, or any platform with Swift probably)

```bash
swift build -c release
cp .build/release/SortLine /usr/local/bin/sortline
```

## Usage

Sort imports in a file:
```bash
sortline <file>
```

Sort multiple files:
```bash
sortline file1.py file2.py file3.py
```

Process a directory:
```bash
find . -name "*.py" -exec sortline {} +
```

### Options

- `-h`: Show help message
- `--verbose`: Print progress information
- `--all-types`: Sort all lines by length (not just imports)

## How It Works

Sorts Python `import` and `from` statements by length, shortest first. Excludes multi-line imports (those with parentheses) and preserves non-import lines in their original positions.

## Version

1.3.1
