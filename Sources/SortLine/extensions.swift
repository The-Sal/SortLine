//
//  File.swift
//  SortLine
//
//  Created by Sal Faris on 20/04/2026.
//

import Foundation


extension String{
    func contains(strings: [String]) -> Bool{
        for string in strings {
            if self.contains(string) {
                return true
            }
        }
        return false
    }
}
