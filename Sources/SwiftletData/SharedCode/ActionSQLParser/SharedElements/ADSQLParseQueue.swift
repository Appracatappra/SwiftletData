//
//  ADSQLParseStack.swift
//  ActionControls
//
//  Created by Kevin Mullins on 10/19/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/**
 Holds the decomposed parts of a SQL command string while it is being parsed.
 */
class ADSQLParseQueue {
    
    // MARK: - Enumerations
    enum parserState {
        // Seeking the start of a new keyword.
        case seekKey
        
        // Parsing a current keyword.
        case inKeyword
        
        // Parsing a single quoted value (').
        case inSingleQuote
        
        // Parsing a double quoted value (").
        case inDoubleQuote
        
        // Parsing an inline comment started by --. Everything to the end of the current line will be considered part of the comment.
        case inComment
    }
    
    // MARK: Static Properties
    /// A common, shared instance of the `ADSQLParseQueue` used across object instances.
    static var shared = ADSQLParseQueue()
    
    // MARK: - Properties
    /// An array of the decomposed parts of the SQL string
    var queue: [String] = []
    
    /// Returns the number of elements initially parsed in the command string.
    var count: Int {
        return queue.count
    }
    
    // MARK: - Initializers
    init() {
        
    }
    
    // MARK: - Functions
    /// Pushes a parsed element into the end of the queue.
    /// - Parameter element: An individual element parsed from the SQL command string to add to the queue.
    func push(element: String) {
        queue.append(element)
    }
    
    /// Replaces the last element pushed into the queue with the given value.
    /// - Parameter element: The element value to replace the last one
    func replaceLastElement(withElement element: String) {
        precondition(count > 0, "Empty parse queue.")
        queue[count - 1] = element
    }
    
    /// Removes the last element pushed into the parse queue.
    func removeLastElement() {
        precondition(count > 0, "Empty parse queue.")
        queue.remove(at: count - 1)
    }
    
    /// Removes the top most element from the front of the queue.
    /// - Returns: The top most element from the parse queue.
    @discardableResult func pop() -> String {
        precondition(count > 0, "Empty parse queue.")
        let element = queue.first
        queue.remove(at: 0)
        return element!
    }
    
    /// Returns the next element that will be popped off the parse queue.
    /// - Returns: The next element that will be popped off the queue or an empth string ("") if an element doesn't exist.
    func lookAhead() -> String {
        if count < 1 {
            return ""
        } else {
            return queue[0]
        }
    }
    
    /// Parses the given SQL command into an array of decomposed elements stored in the parse queue.
    /// - Parameter sql: The SQL command string to parse.
    func parse(_ sql: String) throws {
        var state: parserState = .seekKey
        var lastChar = ""
        var value = ""
        var key = ""
        var nest = 0
        
        // Empty current queue
        queue = []
        
        // Process all characters in the SQL command
        // KKM - changed from sql.characters
        for c in sql {
            let char = String(c)
            
            // Take action based on character and state.
            switch(char) {
            case " ", "\t":
                switch(state) {
                case .seekKey:
                    break
                case .inKeyword:
                    push(element: key)
                    state = .seekKey
                    key = ""
                case .inComment:
                    break
                default:
                    value += char
                }
            case "\n", "\r":
                switch(state) {
                case .seekKey:
                    break
                case .inKeyword:
                    push(element: key)
                    state = .seekKey
                    key = ""
                case .inComment:
                    value = ""
                    key = ""
                    state = .seekKey
                default:
                    value += char
                }
            case "'":
                switch(state) {
                case .seekKey:
                    state = .inSingleQuote
                case .inSingleQuote:
                    if lastChar == "'" {
                        // Empty string?
                        if value.isEmpty {
                            push(element: "EMPTY_STRING")
                            value = ""
                            state = .seekKey
                        } else {
                            // Embedded single quote.
                            value += "'"
                            lastChar = ""
                        }
                    } else {
                        push(element: value)
                        value = ""
                        state = .seekKey
                    }
                case .inComment:
                    break
                default:
                    value += char
                }
            case "\"":
                switch(state) {
                case .seekKey:
                    state = .inDoubleQuote
                case .inDoubleQuote:
                    if lastChar == "\"" {
                        // Empty string?
                        if value.isEmpty {
                            push(element: "EMPTY_STRING")
                            value = ""
                            state = .seekKey
                        } else {
                            // Embedded double quote.
                            value += "\""
                            lastChar = ""
                        }
                    } else {
                        push(element: value)
                        value = ""
                        state = .seekKey
                    }
                case .inComment:
                    break
                default:
                    value += char
                }
            case "(":
                switch(state) {
                case .seekKey:
                    push(element: char)
                    key = ""
                    nest += 1
                case .inKeyword:
                    push(element: key)
                    push(element: char)
                    key = ""
                    nest += 1
                    state = .seekKey
                case .inComment:
                    break
                default:
                    value += char
                }
            case ")":
                switch(state) {
                case .seekKey:
                    push(element: char)
                    key = ""
                    nest -= 1
                    if nest < 0 {
                        throw ADSQLParseError.mismatchedParenthesis(message: "Parsing: \(key)")
                    }
                case .inKeyword:
                    push(element: key)
                    push(element: char)
                    key = ""
                    nest -= 1
                    if nest < 0 {
                        throw ADSQLParseError.mismatchedParenthesis(message: "Parsing: \(key)")
                    }
                    state = .seekKey
                case .inComment:
                    break
                default:
                    value += char
                }
            case "*":
                switch(state){
                case .seekKey:
                    push(element: char)
                    key = ""
                case .inKeyword:
                    key += char
                    push(element: key)
                    key = ""
                    state = .seekKey
                case .inComment:
                    break
                default:
                    value += char
                }
            case ",", "+", "/", "!", ";", "<", ">":
                switch(state){
                case .seekKey:
                    push(element: char)
                    key = ""
                case .inKeyword:
                    push(element: key)
                    push(element: char)
                    key = ""
                    state = .seekKey
                case .inComment:
                    break
                default:
                    value += char
                }
            case "=":
                switch(state){
                case .seekKey:
                    if lastChar == "!" {
                        replaceLastElement(withElement: "!=")
                        lastChar = ""
                    } else if lastChar == "<" {
                        replaceLastElement(withElement: "<=")
                        lastChar = ""
                    } else if lastChar == ">" {
                        replaceLastElement(withElement: ">=")
                        lastChar = ""
                    } else {
                        push(element: char)
                    }
                    key = ""
                case .inKeyword:
                    if lastChar == "!" {
                        replaceLastElement(withElement: "!=")
                        lastChar = ""
                    } else if lastChar == "<" {
                        replaceLastElement(withElement: "<=")
                        lastChar = ""
                    } else if lastChar == ">" {
                        replaceLastElement(withElement: ">=")
                        lastChar = ""
                    } else {
                        push(element: key)
                        push(element: char)
                    }
                    key = ""
                    state = .seekKey
                case .inComment:
                    break
                default:
                    value += char
                }
            case "-":
                switch(state){
                case .seekKey:
                    if lastChar == "-" {
                        state = .inComment
                        removeLastElement()
                        lastChar = ""
                    } else {
                        push(element: char)
                    }
                    key = ""
                case .inKeyword:
                    if lastChar == "-" {
                        state = .inComment
                        removeLastElement()
                        lastChar = ""
                    } else {
                        push(element: key)
                        push(element: char)
                    }
                    key = ""
                    state = .seekKey
                case .inComment:
                    break
                default:
                    value += char
                }
            default:
                switch(state) {
                case .seekKey:
                    key += char
                    state = .inKeyword
                case .inKeyword:
                    key += char
                case .inComment:
                    break
                default:
                    value += char
                }
            }
            
            lastChar = char
        }
        
        // Validate terminating state
        switch (state) {
        case .inSingleQuote:
            throw ADSQLParseError.mismatchedSingleQuotes(message: "Parsing Section: \(value)")
        case .inDoubleQuote:
            throw ADSQLParseError.mismatchedDoubleQuotes(message: "Parsing Section: \(value)")
        default:
            if nest > 0 {
                throw ADSQLParseError.mismatchedParenthesis(message: "Parsing Section: \(key)")
            }
        }
        
        // Handle any trailing values
        if !key.isEmpty {
            push(element: key)
        }
        
        if !value.isEmpty {
            push(element: value)
        }
    }
}
