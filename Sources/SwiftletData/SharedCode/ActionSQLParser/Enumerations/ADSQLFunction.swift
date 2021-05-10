//
//  ADSQLFunction.swift
//  ActionControls
//
//  Created by Kevin Mullins on 10/26/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/// Defines the type of functions that can be called in a SQL expression.
public enum ADSQLFunction: String {
    // MARK: - String Functions
    /// Trims any white spaces off of the left side of a string.
    case ltrim = "ltrim"
    
    /// Trims any white spaces off both sides of a string.
    case trim = "trim"
    
    /// Tests to see if one string contains another.
    case instr = "instr"
    
    /// Replaces all instances of one string inside another.
    case replace = "replace"
    
    /// Converts the string to upper case.
    case upper = "upper"
    
    /// Returns the length of the string in characters.
    case length = "length"
    
    /// Trims any white spaces off of the right side of the string.
    case rtrim = "rtrim"
    
    /// Converts the string to lower case.
    case lower = "lower"
    
    /// Returns the requested portion of the string.
    case substr = "substr"
    
    // MARK: - Numeric/Math Functions
    /// Returns the absolute value of a number.
    case abs = "abs"
    
    /// Returns the maximum value of a group of numbers.
    case max = "max"
    
    /// Rounds the given number.
    case round = "round"
    
    /// Returns the average of a group of numbers.
    case avg = "avg"
    
    /// Returns the minimum value of a group of numbers.
    case min = "min"
    
    /// Returns the sum of a group of numbers.
    case sum = "sum"
    
    /// Returns the number of records in a group.
    case count = "count"
    
    /// Returns a random number
    case random = "random"
    
    // MARK: - Date/Time Functions
    /// Returns the date in this format: YYYY-MM-DD.
    case date = "date"
    
    /// Returns the current date in Julian notation.
    case julianday = "julianday"
    
    /// Formats the date as a string based on a set of formatting instructions.
    case strftime = "strftime"
    
    /// Returns the current date and time in the YYYY-MM-DD HH:MM:SS format.
    case datetime = "datetime"
    
    /// Returns the current date and time.
    case now = "now"
    
    /// Returns the time as HH:MM:SS
    case time = "time"
    
    // MARK: - Advanced Functions
    /// Accepts two or more arguments and returns the first non-null argument
    case coalesce = "coalesce"
    
    /// Returns the ID of the last row inserted into any table.
    case lastInsertedRowID = "last_insert_rowid"
    
    /// Accepts two or more arguments and returns the first non-null argument.
    case ifNull = "ifnull"
    
    /// Returns `NULL` if any of the passed values are null.
    case nullIf = "nullif"
    
    // MARK: - Internal Functions
    /// Handles an internal check operation.
    case check = "@check"
    
    // MARK: - Custom Functions
    /// Performs a comparison and returns one value if the comparison is `true` and another if it is `false`.
    case compare = "compare"
    
    // MARK: - Initializers
    /**
     Attempts to return a function type for the given string value.
     
     - Parameter text: The name of a function.
     - Returns: The function type or `nil` if not found.
    */
    public static func get(fromString text: String) -> ADSQLFunction? {
        let value = text.lowercased()
        return ADSQLFunction(rawValue: value)
    }
}
