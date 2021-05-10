//
//  ADSQLUnaryExpression.swift
//  ActionControls
//
//  Created by Kevin Mullins on 10/24/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/// Defines a unary expression used in a SQL instruction such as forcing a value to be positive or negative.
public class ADSQLUnaryExpression: ADSQLExpression {
    
    // MARK: - Enumerations
    /// Defines the type of unary expression.
    public enum UnaryOperation: String {
        /// Force a value to be positive.
        case positive
        
        /// Force a value to be negative.
        case negative
        
        /// Negate a boolean value.
        case not
        
        /// Group a value.
        case group
    }
    
    // MARK: - Properties
    /// The type of unary operation to perform.
    public var operation: UnaryOperation
    
    /// The value that is being operated on.
    public var value: ADSQLExpression
    
    // MARK: - Initializers
    public init(operation: UnaryOperation, value: ADSQLExpression) {
        self.operation = operation
        self.value = value
    }
    
    /**
     Decodes the expression from an Instance Dictionary that has been read from a Swift Portable Object Notation (SPON) stream.
     - Parameter dictionary: A `ADInstanceDictionary` representing the values for the expression.
     */
    public required init(fromInstance dictionary: ADInstanceDictionary) {
        self.operation = .group
        self.value = ADSQLLiteralExpression(value: "")
        self.decode(fromInstance: dictionary)
    }
    
    // MARK: - Functions
    /**
     Evaluates the given expression and returns a result based on the data in the record passed in.
     - Parameter row: A `ADRecord` containing values to be evaluated against the expression.
     - Returns: The result of the evaluation.
     */
    @discardableResult public func evaluate(forRecord row: ADRecord? = nil) throws -> Any? {
        
        // Get the base value
        let result = try value.evaluate(forRecord: row)
        
        // Take action based on the operation
        switch operation {
        case .positive:
            if let val = result as? Int {
                return +val
            } else if let val = result as? Float {
                return +val
            } else {
                throw ADSQLExecutionError.syntaxError(message: "Unable to convert `\(String(describing: result))` into a positive value.")
            }
        case .negative:
            if let val = result as? Int {
                return -val
            } else if let val = result as? Float {
                return -val
            } else {
                throw ADSQLExecutionError.syntaxError(message: "Unable to convert `\(String(describing: result))` into a negative value.")
            }
        case .not:
            if let val = result as? Bool {
                return !val
            } else {
                throw ADSQLExecutionError.syntaxError(message: "NOT only valid on BOOLEAN values.")
            }
        case .group:
            return result
        }
        
    }
    
    /**
     Encodes the expression into an Instance Dictionary for storage in a Swift Portable Object Notation (SPON) format.
     -Returns: The expression represented as an Instance Dictionary.
     */
    public func encode() -> ADInstanceDictionary {
        let dictionary = ADInstanceDictionary()
        
        // Save values
        dictionary.typeName = "Unary"
        dictionary.storage["operation"] = operation.rawValue
        dictionary.storage["value"] = value.encode()
        
        return dictionary
    }
    
    /**
     Decodes the expression from an Instance Dictionary that has been read from a Swift Portable Object Notation (SPON) stream.
     - Parameter dictionary: A `ADInstanceDictionary` representing the values for the expression.
     */
    public func decode(fromInstance dictionary: ADInstanceDictionary) {
        if let value = dictionary.storage["operation"] as? String {
            operation = UnaryOperation(rawValue: value)!
        }
        if let exp = dictionary.storage["value"] as? ADInstanceDictionary {
            value = ADSQLExpressionBuilder.build(fromInstance: exp)!
        }
    }
        
}
