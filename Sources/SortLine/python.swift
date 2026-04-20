//
//  python.swift
//  SortLine
//
//  Created by Sal Faris on 20/04/2026.
//

import Foundation

enum PythonLinterError: Error {
    case LR_P2(String)
    case LR_P7(String)
}

struct LintResult {
    var lineNum: Int
    var error: PythonLinterError
}

class SkipLint {
    var lines: [String]
    // Pre-computed: for each line, are we inside a multi-line string?
    var inStringAtLine: [Bool]

    init(lines: [String]) {
        self.lines = lines
        self.inStringAtLine = SkipLint.computeStringState(lines: lines)
    }

    /// Compute for each line whether we're inside a multi-line string
    static func computeStringState(lines: [String]) -> [Bool] {
        var result = Array(repeating: false, count: lines.count)
        var inMultiLineString = false
        var delimiter: String? = nil

        for (i, line) in lines.enumerated() {
            result[i] = inMultiLineString

            if inMultiLineString {
                // Check if this line ends the multi-line string
                if line.contains(delimiter!) {
                    // Count occurrences - if even number, string continues
                    // if odd, string ends
                    let count = line.components(separatedBy: delimiter!).count - 1
                    if count % 2 == 1 {
                        inMultiLineString = false
                        delimiter = nil
                    }
                }
            } else {
                // Check if this line starts a multi-line string
                // Handle """ strings
                let tripleDoubleCount = line.components(separatedBy: "\"\"\"").count - 1
                if tripleDoubleCount > 0 {
                    // If odd count, we're entering a multi-line string
                    if tripleDoubleCount % 2 == 1 {
                        inMultiLineString = true
                        delimiter = "\"\"\""
                    }
                    // If even, it's just quotes on same line - no state change
                }

                // Handle ''' strings (only if not already in a """ string)
                if !inMultiLineString {
                    let tripleSingleCount = line.components(separatedBy: "'''").count - 1
                    if tripleSingleCount > 0 && tripleSingleCount % 2 == 1 {
                        inMultiLineString = true
                        delimiter = "'''"
                    }
                }
            }
        }

        return result
    }

    func shouldLint(position: Int) -> Bool {
        // position is 1-indexed line number
        let lineIndex = position - 1  // Convert to 0-indexed array index

        // Check for file-level nolint comment
        if !self.lines.isEmpty && self.lines[0].trimmingCharacters(in: .whitespaces) == "# sortline-nolint" {
            return false
        }

        // Check for inline nolint comment on the line being checked
        if lineIndex >= 0 && lineIndex < self.lines.count {
            if self.lines[lineIndex].contains("# sortline-nolint") {
                return false
            }
        }

        // Don't lint if we're inside a multi-line string
        if lineIndex >= 0 && lineIndex < self.inStringAtLine.count {
            return !self.inStringAtLine[lineIndex]
        }

        return true
    }

}

class PythonLinter {

    var rules: [([String]) throws -> [LintResult]]

    init(rules: [([String]) throws -> [LintResult]]) {
        self.rules = rules
    }

    init() {
        self.rules = [
            PythonLinter.python7,
            // PythonLinter.python2
        ]
    }

    func lint(at filePath: String) {
        let content = try! String(contentsOf: .init(filePath: filePath), encoding: .utf8)
        for rule in self.rules {
            do {
                // Use omittingEmptySubsequences: false to preserve blank lines for accurate line numbers
                let results = try rule(
                    content.split(separator: "\n", omittingEmptySubsequences: false).map({ subString in String(subString) }))
                for result in results {
                    print("File: \(filePath), Line: \(result.lineNum), Error: \(result.error)")
                }
            } catch {
                print("File: \(filePath), Error: \(error)")
            }
        }
    }

    /// **LR.P7** – Dicts and Arrays must have some form of cleanups, there cannot be a collection that grows indefinitely thats held by `self.` acceptable ways to clear are:
    private static func python7(codeLines: [String]) throws -> [LintResult] {
        var symbols: [(String, Int, Int)] = []  // symbol, lineNum, (0=unsatisfied, 1=satisfied)
        var errors = [LintResult]()
        let skipLint = SkipLint(lines: codeLines)
        

        for (lineNum, line) in codeLines.enumerated() {
            if line.first == "#" { continue }
            if !skipLint.shouldLint(position: lineNum + 1) { continue }
            let strippedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if strippedLine.hasPrefix("self.") {
                let expressionAssigned = strippedLine.split(separator: "=")
                if expressionAssigned.count > 1 {
                    let value = expressionAssigned[1]
                    if value.contains("{}") {
                        symbols.append(
                            (
                                String(expressionAssigned[0].split(separator: ":")[0])
                                    .trimmingCharacters(in: .whitespaces), lineNum, 0
                            ))
                        continue
                    }
                }
            }

            for (i, symbolData) in symbols.enumerated() {
                let symbol = symbolData.0
                let symbolIsSatisfied = symbolData.2 == 1

                if strippedLine.contains(symbol) && !symbolIsSatisfied {
                    if line.contains(strings: [".pop", "{}", ".remove", "= []", "=[]", "del "]) {
                        symbols[i] = (symbol, symbolData.1, 1)
                    }
                }
            }
        }

        for symbol in symbols {
            if symbol.2 == 0 {
                errors.append(
                    LintResult(
                        lineNum: symbol.1 + 1,  // Convert to 1-indexed
                        error: .LR_P7("The symbol `\(symbol.0)` is never cleared")))
            }
        }

        return errors
    }

    /// **LR.P2** — Imports inside function bodies are not allowed. All imports must be declared at the top of the file. (disabled)
    private static func python2(codeLines: [String]) throws -> [LintResult] {
        var results = [LintResult]()
        let skipLint = SkipLint(lines: codeLines)

        for (lineNum, line) in codeLines.enumerated() {
            if !skipLint.shouldLint(position: lineNum + 1) { continue }
            let stripedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if (stripedLine.hasPrefix("import") || stripedLine.hasPrefix("from"))
                && !(line.hasPrefix("import") || line.hasPrefix("from"))
            {
                results.append(
                    .init(lineNum: lineNum + 1, error: .LR_P2("Violation on \(lineNum + 1) `\(line)`")))
            }
        }

        return results
    }

}
