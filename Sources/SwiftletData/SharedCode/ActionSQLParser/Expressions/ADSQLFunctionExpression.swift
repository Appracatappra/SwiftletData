//
//  ADSQLFunctionExpression.swift
//  ActionControls
//
//  Created by Kevin Mullins on 10/26/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/// Defines a function being called in a SQL instruction such as `count` or `sum`.
public class ADSQLFunctionExpression: ADSQLExpression {
    
    // MARK: - Static Properties
    /// If `true` and the function is an aggregate function, the function is in the accumulation pass where it is accumulating values. If `false` the function will simply report the values acquired in the accumulation pass.
    public static var accumulate = true
    
    // MARK: - Private properties
    private var maxValue: Float = 0.0
    private var minValue: Float = 0.0
    private var sumValue: Float = 0.0
    private var recordCount: Float = 0.0
    
    // MARK: - Properties
    /// The type of function being performed.
    public var functionType: ADSQLFunction
    
    /// The list of optional parameters being passed to the function.
    public var parameters: [ADSQLExpression] = []
    
    /// Returns `true` if the function is one of the aggregate functions: COUNT, MIN, MAX, AVG, SUM.
    public var isAggregate: Bool {
        switch functionType {
        case .count, .min, .max, .avg, .sum:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Initializers
    /**
     Creates a new Function Expression instance.
     
     - Parameters:
         - function: The type of function being called.
         - parameters: A list of optional parameters being passed to the function.
    */
    public init(functionType function: ADSQLFunction, parameters: [ADSQLExpression]) {
        self.functionType = function
        self.parameters = parameters
    }
    
    /**
     Decodes the expression from an Instance Dictionary that has been read from a Swift Portable Object Notation (SPON) stream.
     - Parameter dictionary: A `ADInstanceDictionary` representing the values for the expression.
     */
    public required init(fromInstance dictionary: ADInstanceDictionary) {
        self.functionType = .abs
        self.decode(fromInstance: dictionary)
    }
    
    // MARK: - Functions
    /**
     Evaluates the given expression and returns a result based on the data in the record passed in.
     - Parameter row: A `ADRecord` containing values to be evaluated against the expression.
     - Returns: The result of the evaluation.
     */
    @discardableResult public func evaluate(forRecord row: ADRecord? = nil) throws -> Any? {
        var values: [Any?] = []
        
        // Get the values from all of the parameters
        for parameter in parameters {
            values.append(try parameter.evaluate(forRecord: row))
        }
        
        // Take action based on the function type
        switch functionType {
        case .ltrim:
            try ensureParameterCount(equals: 1)
            if let v1 = values[0] as? String {
                return ltrim(v1)
            }
        case .trim:
            try ensureParameterCount(equals: 1)
            if let v1 = values[0] as? String {
                return trim(v1)
            }
        case .instr:
            try ensureParameterCount(equals: 2)
            if let v1 = values[0] as? String {
                if let v2 = values[1] as? String {
                    return instr(v1, contains: v2)
                }
            }
        case .replace:
            try ensureParameterCount(equals: 3)
            if let v1 = values[0] as? String {
                if let v2 = values[1] as? String {
                    if let v3 = values[2] as? String {
                        return replace(v1, find: v2, replaceWith: v3)
                    }
                }
            }
        case .upper:
            try ensureParameterCount(equals: 1)
            if let v1 = values[0] as? String {
                return upper(v1)
            }
        case .length:
            try ensureParameterCount(equals: 1)
            if let v1 = values[0] as? String {
                return length(v1)
            }
        case .rtrim:
            try ensureParameterCount(equals: 1)
            if let v1 = values[0] as? String {
                return rtrim(v1)
            }
        case .lower:
            try ensureParameterCount(equals: 1)
            if let v1 = values[0] as? String {
                return lower(v1)
            }
        case .substr:
            try ensureParameterCount(between: 2, and: 3)
            if let v1 = values[0] as? String {
                if let v2 = values[1] as? Int {
                    if parameters.count == 3 {
                        if let v3 = values[2] as? Int {
                            return substr(v1, start: v2, length: v3)
                        }
                    } else {
                        return substr(v1, start: v2)
                    }
                }
            }
        case .abs:
            try ensureParameterCount(equals: 1)
            if let v1 = values[0] as? Int {
                return abs(v1)
            } else if let v1 = values[0] as? Float {
                return abs(v1)
            }
        case .max:
            if ADSQLFunctionExpression.accumulate {
                try ensureParameterCount(equals: 1)
                if let v1 = values[0] as? Int {
                    let v2 = Float(v1)
                    if v2 > maxValue {
                        maxValue = v2
                    }
                    return maxValue
                } else if let v1 = values[0] as? Float {
                    if v1 > maxValue {
                        maxValue = v1
                    }
                    return maxValue
                }
            } else {
                return maxValue
            }
        case .round:
            try ensureParameterCount(equals: 1)
            if let v1 = values[0] as? Float {
                return round(v1)
            }
        case .avg:
            if ADSQLFunctionExpression.accumulate {
                try ensureParameterCount(equals: 1)
                if let v1 = values[0] as? Int {
                    sumValue += Float(v1)
                    recordCount += 1
                    return (sumValue / recordCount)
                } else if let v1 = values[0] as? Float {
                    sumValue += v1
                    recordCount += 1
                    return (sumValue / recordCount)
                }
            } else {
                return (sumValue / recordCount)
            }
        case .min:
            if ADSQLFunctionExpression.accumulate {
                try ensureParameterCount(equals: 1)
                if let v1 = values[0] as? Int {
                    let v2 = Float(v1)
                    if v2 < minValue {
                        minValue = v2
                    }
                    return minValue
                } else if let v1 = values[0] as? Float {
                    if v1 < minValue {
                        minValue = v1
                    }
                    return minValue
                }
            } else {
                return minValue
            }
        case .sum:
            if ADSQLFunctionExpression.accumulate {
                try ensureParameterCount(equals: 1)
                if let v1 = values[0] as? Int {
                    sumValue += Float(v1)
                    return sumValue
                } else if let v1 = values[0] as? Float {
                    sumValue += v1
                    return sumValue
                }
            } else {
               return sumValue
            }
        case .count:
            if ADSQLFunctionExpression.accumulate {
                try ensureParameterCount(equals: 1)
                recordCount += 1
                return Int(recordCount)
            } else {
                return Int(recordCount)
            }
        case .random:
            let params = parameters.count
            switch params {
            case 0:
                return Int(arc4random_uniform(64000000))
            case 1:
                if let v1 = values[0] as? Int {
                    return Int(arc4random_uniform(UInt32(v1)))
                }
            case 2:
                if let v1 = values[0] as? Int {
                    if let v2 = values[1] as? Int {
                        return v1 + Int(arc4random_uniform(UInt32(v2 - v1)))
                    }
                }
            default:
                throw ADSQLExecutionError.syntaxError(message: "Function RANDOM takes between 0 and 2 parameters but received \(params).")
            }
        case .compare:
            try ensureParameterCount(equals: 3)
            if let c1 = values[0] as? Bool {
                if c1 {
                    // Return the true value
                    return values[1]
                } else {
                    // Return the false value
                    return values[2]
                }
            }
        case .coalesce:
            for value in values {
                if value != nil {
                    return value
                }
            }
            return nil
        case .ifNull:
            try ensureParameterCount(equals: 2)
            if values[0] == nil {
                return values[1]
            } else {
                return values[0]
            }
        case .nullIf:
            try ensureParameterCount(equals: 2)
            if let v1 = values[0] as? String {
                if let v2 = values[1] as? String {
                    if v1 == v2 {
                        return nil
                    } else {
                        return v1
                    }
                }
            }
        case .check:
            try ensureParameterCount(equals: 1)
            if let v1 = values[0] as? Bool {
                return v1
            }
        default:
            throw ADSQLExecutionError.unsupportedCommand(message: "ADDataStore does not support function `\(functionType)`.")
        }
        
        // TODO: Handle date functions.
        
        // Error
        throw ADSQLExecutionError.syntaxError(message: "On function call `\(functionType)`.")
    }
    
    /**
     Ensures the proper number of parameters have been passed to a given function call.
     - Parameter num: The number of required parameters.
     - Remark: Throws an error if the proper number of parameters have not been provided.
     */
    public func ensureParameterCount(equals num: Int) throws {
        if parameters.count != num {
            let plural = (num == 1) ? "" : "s"
            throw ADSQLExecutionError.syntaxError(message: "Function `\(functionType)` takes \(num) parameter\(plural).")
        }
    }
    
    /**
     Ensures the proper number of parameters have been passed to a given function call.
     - Parameters:
         - min: The minimal number of parameters.
         - max: The maximum number of parameters.
     - Remark: Throws an error if the proper number of parameters have not been provided.
     */
    public func ensureParameterCount(between min: Int, and max: Int) throws {
        if parameters.count < min || parameters.count > max {
            throw ADSQLExecutionError.syntaxError(message: "Function `\(functionType)` takes betweeb \(min) and \(max) parameters.")
        }
    }
    
    /**
     Encodes the expression into an Instance Dictionary for storage in a Swift Portable Object Notation (SPON) format.
     -Returns: The expression represented as an Instance Dictionary.
     */
    public func encode() -> ADInstanceDictionary {
        let dictionary = ADInstanceDictionary()
        let array = ADInstanceArray()
        
        // Save parameters into the array
        for parameter in parameters {
            array.storage.append(parameter.encode())
        }
        
        // Save values
        dictionary.typeName = "Function"
        dictionary.storage["functionType"] = functionType.rawValue
        dictionary.storage["parameters"] = array
        
        return dictionary
    }
    
    /**
     Decodes the expression from an Instance Dictionary that has been read from a Swift Portable Object Notation (SPON) stream.
     - Parameter dictionary: A `ADInstanceDictionary` representing the values for the expression.
     */
    public func decode(fromInstance dictionary: ADInstanceDictionary) {
        if let value = dictionary.storage["functionType"] as? String {
            functionType = ADSQLFunction(rawValue: value)!
        }
        if let array = dictionary.storage["parameters"] as? ADInstanceArray {
            for item in array.storage {
                if let exp = item as? ADInstanceDictionary {
                    if let expression = ADSQLExpressionBuilder.build(fromInstance: exp) {
                        parameters.append(expression)
                    }
                }
            }
        }
    }
    
    // MARK: - String Functions
    /**
     Trims the white space characters from the left side of a string.
     - Parameter value: The string to trim.
     - Returns: The string with the white space characters removed.
    */
    private func ltrim(_ value: String) -> String {
        let sets = "\u{020}\u{009}\u{00A}\u{00D}\u{000}\u{00B}"
        var trimmed = ""
        var trimming = true
        
        for character in value {
            if trimming {
                if !sets.contains(character) {
                   trimmed += "\(character)"
                    trimming = false
                }
            } else {
                trimmed += "\(character)"
            }
        }
        
        // Return the trimmed string
        return trimmed
    }
    
    /**
     Trims the white space characters from the both sides of a string.
     - Parameter value: The string to trim.
     - Returns: The string with the white space characters removed.
     */
    private func trim(_ value: String) -> String {
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /**
     Trims the white space characters from the right side of a string.
     - Parameter value: The string to trim.
     - Returns: The string with the white space characters removed.
     */
    private func rtrim(_ value: String) -> String {
        let sets = "\u{020}\u{009}\u{00A}\u{00D}\u{000}\u{00B}"
        var trimmed = ""
        var trimming = true
        let chars = Array(value)
        
        var n = value.count - 1
        while n >= 0 {
            let character = chars[n]
            if trimming {
                if !sets.contains(character) {
                    trimmed += "\(character)"
                    trimming = false
                }
            } else {
                trimmed += "\(character)"
            }
            
            // Decrement
            n -= 1
        }
        
        // Return the trimmed string
        return trimmed
    }
    
    /**
     Checks to see if one string contains another.
     - Parameters:
         - value: The string to check.
         - pattern: The string to check for.
     - Returns: `true` if the value contains the pattern, else `false`.
    */
    private func instr(_ value: String, contains pattern: String) -> Bool {
        return value.contains(pattern)
    }
    
    /**
     Replaces all occurences of one string with another inside of the target string.
     
     - Parameters:
         - value: The string to replace substring in.
         - find: The pattern to find.
         - replace: The string to replace the pattern with.
     - Returns: The string with all occurrences on find replaced with replace.
    */
    private func replace(_ value: String, find: String, replaceWith replace: String) -> String {
        return value.replacingOccurrences(of: find, with: replace)
    }
    
    /**
     Converts the string to uppercase.
     - Parameter value: The string to convert.
     - Returns: The string converted to uppercase.
    */
    private func upper(_ value: String) -> String {
        return value.uppercased()
    }
    
    /**
     Returns the number of characters inside of the string.
     - Parameter value: The string to count characters in.
     - Returns: The number of characters in the string.
    */
    private func length(_ value: String) -> Int {
        return value.count
    }
    
    /**
     Converts the string to lowercase.
     - Parameter value: The string to convert.
     - Returns: The string converted to lowercase.
     */
    private func lower(_ value: String) -> String {
        return value.lowercased()
    }
    
    /**
     Returns a section of the source string.
     - Parameters:
         - value: The string to slice a section from.
         - start: The starting position for the slice.
         - length: The length of the slice. If 0, the slice will run to the end of the string.
     - Returns: The specified section sliced from the string.
    */
    private func substr(_ value: String, start: Int, length: Int = 0) -> String {
        if length == 0 {
            let range = value.index(value.startIndex, offsetBy: start + 1)..<value.endIndex
            return String(value[range])
        } else {
            let range = value.index(value.startIndex, offsetBy: start + 1)..<value.index(value.startIndex, offsetBy: start + 1 + length)
            return String(value[range])
        }
    }
    
}
