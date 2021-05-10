//
//  ADSQLParseError.swift
//  ActionControls
//
//  Created by Kevin Mullins on 10/20/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/// Defines the type of errors that can arise when parsing a SQL command string.
public enum ADSQLParseError: Error {
    /// The parser encountered an unknown keyword in the SQL Command. `message` contains the details of the given failure.
    case unknownKeyword(message: String)
    
    /// The parser encountered an unknown function name in the SQL Command. `message` contains the details of the given failure.
    case unknownFunctionName(message: String)
    
    /// The parser encountered an invalid keyword in the SQL Command. `message` contains the details of the given failure.
    case invalidKeyword(message: String)
    
    /// The parser encountered a value in single quotes that is not properly terminated. `message` contains the details of the given failure.
    case mismatchedSingleQuotes(message: String)
    
    /// The parser encountered a value in double quotes that is not properly terminated. `message` contains the details of the given failure.
    case mismatchedDoubleQuotes(message: String)
    
    /// The parser encountered a value in parenthesis that is not properly terminated. `message` contains the details of the given failure.
    case mismatchedParenthesis(message: String)
    
    /// The parser encountered a value that it was not expecting. `message` contains the details of the given failure.
    case malformedSQLCommand(message: String)
    
    /// The parser expected an integer as the next value. `message` contains the details of the given failure.
    case expectedIntValue(message: String)
}
