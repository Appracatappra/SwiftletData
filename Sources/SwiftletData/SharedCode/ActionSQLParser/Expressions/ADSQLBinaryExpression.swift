//
//  ADSQLBinaryExpression.swift
//  ActionControls
//
//  Created by Kevin Mullins on 10/26/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/// Defines a binary operation being performed on two expressions in a SQL instruction such as adding two values or comparing two values to see if they are equal.
public class ADSQLBinaryExpression: ADSQLExpression {
    
    // MARK: - Enumerations
    /// Defines the type of binary operation being performed.
    public enum BinaryOperation: String {
        /// Adding two values.
        case addition
        
        /// Subtracting one value from another.
        case subtraction
        
        /// Multiplying two values.
        case multiplication
        
        /// Dividing a value by another.
        case division
        
        /// Testing to see if two values are equal.
        case equalTo
        
        /// Testing to see if two values are not equal.
        case notEqualTo
        
        /// Testing to see if one value is less than another.
        case lessThan
        
        /// Testing to see if one value is greater than another.
        case greaterThan
        
        /// Testing to see if one value is less than or equal to another.
        case lessThanOrEqualTo
        
        /// Testing to see if one value is greater than or equal to another.
        case greaterThanOrEqualTo
        
        /// Testing to see if both values are `true`.
        case and
        
        /// Testing to see if either value is `true`.
        case or
        
        /// Casting a value to another type.
        case castTo
        
        /// Perform a collations on both values.
        case collate
        
        /// See if one value is like another.
        case like
        
        /// See if one value is like another.
        case glob
        
        /// Perform a RegEx operation on a value.
        case regexp
        
        /// See if one value matches another.
        case match
    }
    
    // MARK: - Properties
    /// The left side of the binary expression.
    public var leftValue: ADSQLExpression
    
    /// The operation to perform on both values.
    public var operation: BinaryOperation
    
    /// The right side of the binary expression.
    public var rightValue: ADSQLExpression?
    
    /// If `true`, negate a binary value result, else `false`.
    public var negate = false
    
    // MARK: - Initializers
    /**
     Initializes a new Binary Expression.
     
     - Parameters:
         - leftValue: The left side of the binary expression.
         - operation: The operation to perform.
         - rightValue: The right side of the binary operation.
    */
    public init(leftValue: ADSQLExpression, operation: BinaryOperation, rightValue: ADSQLExpression?,_ negate: Bool = false) {
        self.leftValue = leftValue
        self.operation = operation
        self.rightValue = rightValue
        self.negate = negate
    }
    
    /**
     Decodes the expression from an Instance Dictionary that has been read from a Swift Portable Object Notation (SPON) stream.
     - Parameter dictionary: A `ADInstanceDictionary` representing the values for the expression.
     */
    public required init(fromInstance dictionary: ADInstanceDictionary) {
        self.leftValue = ADSQLLiteralExpression(value: "")
        self.operation = .collate
        self.decode(fromInstance: dictionary)
    }
    
    // MARK: - Functions
    /**
     Evaluates the given expression and returns a result based on the data in the record passed in.
     - Parameter row: A `ADRecord` containing values to be evaluated against the expression.
     - Returns: The result of the evaluation.
     */
    @discardableResult public func evaluate(forRecord row: ADRecord? = nil) throws -> Any? {
        
        // Get both values
        let left = try leftValue.evaluate(forRecord: row)
        let right = try rightValue?.evaluate(forRecord: row)
        
        // Take action based on the desired operation
        if let v1 = left {
            if let v2 = right {
                switch operation {
                case .addition:
                    return ADUtilities.compute(v1, .plus, v2)
                case .subtraction:
                    return ADUtilities.compute(v1, .minus, v2)
                case .multiplication:
                    return ADUtilities.compute(v1, .times, v2)
                case .division:
                    return ADUtilities.compute(v1, .dividedBy, v2)
                case .and:
                    let result = ADUtilities.compare(v1, .and, v2)
                    return negate ? !result : result
                case .or:
                    let result = ADUtilities.compare(v1, .or, v2)
                    return negate ? !result : result
                case .equalTo:
                    let result = ADUtilities.compare(v1, .equalTo, v2)
                    return negate ? !result : result
                case .notEqualTo:
                    let result =  ADUtilities.compare(v1, .notEqualTo, v2)
                    return negate ? !result : result
                case .lessThan:
                    let result =  ADUtilities.compare(v1, .lessThan, v2)
                    return negate ? !result : result
                case .greaterThan:
                    let result =  ADUtilities.compare(v1, .greaterThan, v2)
                    return negate ? !result : result
                case .lessThanOrEqualTo:
                    let result =  ADUtilities.compare(v1, .lessThanOrEqualTo, v2)
                    return negate ? !result : result
                case .greaterThanOrEqualTo:
                    let result =  ADUtilities.compare(v1, .greaterThanOrEqualTo, v2)
                    return negate ? !result : result
                case .castTo:
                    if let typeName = v2 as? String {
                        if let type = ADSQLColumnType.get(fromString: typeName) {
                            return try ADUtilities.cast(v1, to: type)
                        }
                    }
                    throw ADSQLExecutionError.syntaxError(message: "`\(v2)` is not a valid type for a cast operation.")
                case .like, .match:
                    if let value = v1 as? String {
                        if var pattern = v2 as? String {
                            pattern = pattern.replacingOccurrences(of: "%", with: ".*?")
                            pattern = pattern.replacingOccurrences(of: "_", with: ".")
                            pattern = "^\(pattern)$"
                            let matches = value.range(of: pattern, options: .regularExpression)
                            return (matches != nil)
                        }
                    }
                    throw ADSQLExecutionError.syntaxError(message: "Cannot perform LIKE on values `\(v1)` and `\(v2)`.")
                case .glob:
                    if let value = v1 as? String {
                        if var pattern = v2 as? String {
                            pattern = pattern.replacingOccurrences(of: "*", with: ".*?")
                            pattern = pattern.replacingOccurrences(of: "?", with: ".")
                            pattern = "^\(pattern)$"
                            let matches = value.range(of: pattern, options: .regularExpression)
                            return (matches != nil)
                        }
                    }
                    throw ADSQLExecutionError.syntaxError(message: "Cannot perform GLOB on values `\(v1)` and `\(v2)`.")
                case .regexp:
                    if let value = v1 as? String {
                        if let pattern = v2 as? String {
                            let matches = value.range(of: pattern, options: .regularExpression)
                            return (matches != nil)
                        }
                    }
                    throw ADSQLExecutionError.syntaxError(message: "Cannot perform LIKE on values `\(v1)` and `\(v2)`.")
                default:
                    // TODO: fully support all operations
                    throw ADSQLExecutionError.unsupportedCommand(message: "ADDataStore does not support the `\(operation)` command.")
                }
            }
        }
        
        // Resulted in error
        return nil
    }
    
    /**
     Encodes the expression into an Instance Dictionary for storage in a Swift Portable Object Notation (SPON) format.
     -Returns: The expression represented as an Instance Dictionary.
     */
    public func encode() -> ADInstanceDictionary {
        let dictionary = ADInstanceDictionary()
        
        // Save values
        dictionary.typeName = "Binary"
        dictionary.storage["leftValue"] = leftValue.encode()
        dictionary.storage["operation"] = operation.rawValue
        if let exp = rightValue {
            dictionary.storage["rightValue"] = exp.encode()
        }
        dictionary.storage["negate"] = negate
        
        return dictionary
    }
    
    /**
     Decodes the expression from an Instance Dictionary that has been read from a Swift Portable Object Notation (SPON) stream.
     - Parameter dictionary: A `ADInstanceDictionary` representing the values for the expression.
     */
    public func decode(fromInstance dictionary: ADInstanceDictionary) {
        if let exp = dictionary.storage["leftValue"] as? ADInstanceDictionary {
            leftValue = ADSQLExpressionBuilder.build(fromInstance: exp)!
        }
        if let value = dictionary.storage["operation"] as? String {
            operation = BinaryOperation(rawValue: value)!
        }
        if let exp = dictionary.storage["rightValue"] as? ADInstanceDictionary {
            rightValue = ADSQLExpressionBuilder.build(fromInstance: exp)
        }
        if let value = dictionary.storage["negate"] as? Bool {
            negate = value
        }
    }
}
