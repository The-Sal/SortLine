//
//  lint.swift
//  SortLine
//
//  Created by Sal Faris on 20/04/2026.
//

import Foundation

class Linter{
    let pythonLinter = PythonLinter()
    
    func lint(at filePath: String){
        if filePath.hasSuffix(".py"){
            self.pythonLinter.lint(at: filePath)
        }
    }
}
