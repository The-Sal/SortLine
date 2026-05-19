//
//  rust.swift
//  SortLine
//
//  Created by Sal Faris on 09/04/2026.
//

import Foundation

class RustLinter {
    /// Converts all rust functions and structs (with their fields) into pub(crate)
    static func pub_er(at path: String) {
        if !path.hasSuffix(".rs") {
            return
        }
        let url = URL(fileURLWithPath: path)
        let contents = try! String(contentsOf: url)
        let lines = contents.split(separator: "\n", omittingEmptySubsequences: false)
        var finalFile = [String]()
        var inStructBody = false
        var structBraceDepth = 0

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if inStructBody {
                let openBraces = line.filter { $0 == "{" }.count
                let closeBraces = line.filter { $0 == "}" }.count
                structBraceDepth += openBraces - closeBraces

                if structBraceDepth <= 0 {
                    inStructBody = false
                    finalFile.append(String(line))
                } else if trimmed.hasPrefix("//") || trimmed.hasPrefix("#") || trimmed.isEmpty {
                    finalFile.append(String(line))
                } else if trimmed == "}" || trimmed == "{" {
                    finalFile.append(String(line))
                } else if trimmed.hasPrefix("pub") {
                    finalFile.append(String(line))
                } else {
                    let leadingSpaces = line.prefix(while: { $0 == " " }).count
                    let spacesString = String(repeatElement(" ", count: leadingSpaces))
                    finalFile.append("\(spacesString)pub(crate) \(trimmed)")
                }
                continue
            }

            let hasFn = trimmed.hasPrefix("fn ") && line.contains("{")
            let isStruct = trimmed.range(of: #"^(pub(\([^)]*\))?\s+)?struct\s+"#, options: .regularExpression) != nil

            if isStruct {
                if !trimmed.hasPrefix("pub") {
                    let leadingSpaces = line.prefix(while: { $0 == " " }).count
                    let spacesString = String(repeatElement(" ", count: leadingSpaces))
                    finalFile.append("\(spacesString)pub(crate) \(trimmed)")
                } else {
                    finalFile.append(String(line))
                }

                if line.contains("{") {
                    inStructBody = true
                    structBraceDepth = line.filter { $0 == "{" }.count - line.filter { $0 == "}" }.count
                    if structBraceDepth <= 0 {
                        inStructBody = false
                    }
                }
            } else if hasFn {
                var whiteSpaces = 0
                var strippedLine = ""

                if !line.hasPrefix("fn") {
                    whiteSpaces = line.split(separator: "fn ")[0].count(where: { $0 == " " })
                    strippedLine = "fn" + String(line.split(separator: "fn")[1])
                } else {
                    whiteSpaces = 0
                    strippedLine = String(line)
                }

                let spacesString = String(repeatElement(" ", count: whiteSpaces))
                let updatedLine = "\(spacesString)pub(crate) \(strippedLine)"
                finalFile.append(updatedLine)
            } else {
                finalFile.append(String(line))
            }
        }

        let contentToWrite = finalFile.joined(separator: "\n")
        try! contentToWrite.write(to: url, atomically: true, encoding: .utf8)
    }
}
