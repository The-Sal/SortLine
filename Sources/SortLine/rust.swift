//
//  rust.swift
//  SortLine
//
//  Created by Sal Faris on 09/04/2026.
//

import Foundation

class RustLinter {
    /// Converts all rust functions into pub(crate)
    static func pub_er(at path: String) {
        if !path.hasSuffix(".rs") {
            return
        }
        let url = URL(fileURLWithPath: path)
        let contents = try! String(contentsOf: url)
        let lines = contents.split(separator: "\n", omittingEmptySubsequences: false)
        var finalFile = [String]()
        for line in lines {
            let hasFn = line.trimmingCharacters(in: .whitespaces).hasPrefix("fn ")
            let hasOpenCrulyBrace = line.contains("{")
            if hasFn && hasOpenCrulyBrace {
                var whiteSpaces = 0
                var strippedLine = ""

                if !line.hasPrefix("fn") {
                    whiteSpaces = line.split(separator: "fn ")[0].count(where: { substring in
                        substring == " "
                    })
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
