//
//  File.swift
//  SortLine
//
//  Created by Sal Faris on 20/04/2026.
//

import Foundation

enum PythonLinterError: Error {
    case LR_P1(String)
}

class PythonLinter {
    
    var rules: [([String]) throws -> Void]
    
    init(rules: [([String]) throws -> Void]) {
        self.rules = rules
    }
    
    init(){
        self.rules = [
            PythonLinter.python1
        ]
    }
    
    func lint(at filePath: String){

        
        
        
        
    }
    
    /// **LR.P1** — Within detected multi-threaded contexts, raw dictionary mutation on shared state (i.e. `self.xxx`) is not allowed without a preceding lock. SortLine uses heuristics to infer threading — it won't catch every case, but flags the clear on
    private static func python1(codeLines: [String]) throws{
        for (lineNum, line) in codeLines.enumerated() {
            if (line.contains("import") || line.contains("from")) && !(line.starts(with: "import") || line.starts(with: "from")){
                throw PythonLinterError.LR_P1("\(lineNum)")
            }
        }
    }
    
}
