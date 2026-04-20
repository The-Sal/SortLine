import Foundation

let version = "2.4.5"
let fm = FileManager.default
let cmdLine = CommandLine.arguments
let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
var availablePrefixesByFileType: [String: [Substring]] = [
    "py": ["import", "from"],
    "swift": ["import"],
    "rs": ["use", "mod"],
    "nil-file": [],
]

if cmdLine.contains("-h") || cmdLine.count == 1 {
    //print(CommandLine.arguments.first!)
    print("SortLine: Sorts imports in a file by their length in various languages")
    print("Version:", version)
    print("Usage:")
    print("\tsortline <file1> <file2>...")
    print("Flags:")
    print("\t--all-types: Sorts every line by length")
    print("\t--verbose: Prints the files being sorted")
    exit(0)
}

struct ArgSpace {
    var allTypes: Bool = false
    var verbose: Bool = false
    var rustPub: Bool = false
    var lint: Bool = false
}

final class FileOptimizer {
    private let importPrefixes: [Substring]

    init(importPrefixes: [Substring]) {
        self.importPrefixes = importPrefixes
    }

    func sortFileHighPerformance(at path: String, flags: ArgSpace) -> Int {
        let url = URL(fileURLWithPath: path)

        guard let fileHandle = FileHandle(forReadingAtPath: path),
            let data = try! fileHandle.readToEnd(),
            let content = String(data: data, encoding: .utf8)
        else {
            if flags.verbose {
                print("[System] Failed to read: \(path)")
            }
            return 0
        }

        // Use lazy split for better memory efficiency on large files
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false)
        var result: [Substring] = []
        result.reserveCapacity(lines.count)

        var imports: [(index: Int, line: Substring)] = []
        var firstImportIndex: Int?

        for (i, line) in lines.enumerated() {

            let isImport = importPrefixes.contains { line.hasPrefix($0) }

            if isImport {
                // Fast check for parentheses using UTF8 view
                let hasParens =
                    line.utf8.contains(UInt8(ascii: "(")) || line.utf8.contains(UInt8(ascii: ")"))

                // do the same of curly braces
                let hasUnClosedBraces_0 =
                    line.utf8.contains(UInt8(ascii: "{")) && !line.utf8.contains(UInt8(ascii: "}"))
                let hasUnClosedBraces_1 =
                    !line.utf8.contains(UInt8(ascii: "{")) && line.utf8.contains(UInt8(ascii: "}"))
                let hasUnClosedBraces = hasUnClosedBraces_0 || hasUnClosedBraces_1

                if !hasParens && !hasUnClosedBraces {
                    if firstImportIndex == nil {
                        firstImportIndex = result.count
                    }
                    imports.append((i, line))
                    continue
                }
            }
            result.append(line)
        }

        // Sort imports by length
        imports.sort { $0.line.count < $1.line.count }

        // Insert sorted imports at the correct position
        if let insertPos = firstImportIndex {
            result.insert(contentsOf: imports.map { $0.line }, at: insertPos)
        }

        // Use ContiguousArray for better performance with value types
        let newContent = result.joined(separator: "\n")

        // Write with buffering for large files
        do {
            try newContent.write(to: url, atomically: false, encoding: .utf8)
        } catch {
            print("Error writing to file: \(error)")
        }

        return lines.count
    }

    func sortAllLinesSimple(at path: String) -> Int {
        let url = URL(fileURLWithPath: path)
        guard let fileHandle = FileHandle(forReadingAtPath: path),
            let data = try! fileHandle.readToEnd(),
            let content = String(data: data, encoding: .utf8)
        else {
            print("[System] Failed to read: \(path)")
            return 0
        }

        /// Alegedly this makes it faster rather than naive .sort(by: { $0.1 < $1.1 })
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false)
        var linesWithCounts = lines.map { ($0, $0.count) }
        linesWithCounts.sort(by: { $0.1 < $1.1 })
        let sortedLines = linesWithCounts.map { $0.0 }
        do {
            try sortedLines.joined(separator: "\n").write(
                to: url, atomically: false, encoding: .utf8)
        } catch {
            print("Error writing to file: \(error)")
        }

        return lines.count
    }
}

if CommandLine.arguments.count > 1 {
    var paths = CommandLine.arguments[1...]
    var flags = ArgSpace()

    let cliArgs = CommandLine.arguments
    if cliArgs.contains("--all-types") {
        flags.allTypes = true
        paths.removeAll(where: { $0 == "--all-types" })
        print("[System] Detected --all-types ")
    }

    if cliArgs.contains("--verbose") {
        flags.verbose = true
        paths.removeAll(where: { $0 == "--verbose" })
        print("[System] Detected --verbose ")
    }

    if cliArgs.contains("--cli-path") {
        print(CommandLine.arguments[0])
        exit(0)
    }

    if cliArgs.contains("--rust:pub") || cliArgs.contains("-rpub") {
        flags.rustPub = true
        paths.removeAll(where: { $0 == "--rust:pub" || $0 == "-rpub" })
        print("[System] Detected --rust:pub ")
    }

    if cliArgs.contains("--lint") {
        flags.lint = true
        paths.removeAll(where: { $0 == "--lint" })
        print("[System] Detected --lint")
    }

    var lines = 0
    let pathsArray = Array(paths)
    let lock = NSLock()
    let linter = Linter()

    DispatchQueue.concurrentPerform(iterations: pathsArray.count) { index in
        let path = pathsArray[index]

        guard let fileExtension = path.split(separator: ".").last else {
            print("[System] Error, Unable to determine file extension for \(path)")
            return
        }

        if flags.rustPub {
            RustLinter.pub_er(at: path)
        } else if flags.lint {
            if path.contains(".rs") || path.contains(".py") || path.contains(".swift") {
                linter.lint(at: path)
            }
        } else {
            let optimiser = FileOptimizer(
                importPrefixes: availablePrefixesByFileType[String(fileExtension)]
                    ?? availablePrefixesByFileType["nil-file"]!)
            if flags.verbose { print("[System] Sorting: \(path)...") }
            let result =
                flags.allTypes
                ? optimiser.sortAllLinesSimple(at: path)
                : optimiser.sortFileHighPerformance(at: path, flags: flags)
            lock.lock()
            lines += result
            lock.unlock()
            print("[System] Sorted \(lines) lines, across \(paths.count) files")
        }
    }

    print("[System] Done")
    exit(0)
} else {
    print("[System] Error: Not enough arguments")
}

exit(1)
