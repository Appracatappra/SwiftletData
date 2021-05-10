//
//  ADSQLBetweenExpression.swift
//  ActionControls
//
//  Created by Kevin Mullins on 10/26/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/// Defines a between expression used in a SQL instruction to test if a value is between two other values.
public class ADSQLBetweenExpression: ADSQLExpression {
    
    // MARK: - Properties
    /// The value to test.
    public var value: ADSQLExpression
    
    /// The low range to test against.
    public var lowValue: ADSQLExpression
    
    /// The high range to test against.
    public var highValue: ADSQLExpression
    
    /// If `true`, negate the results of the test, else `false`.
    public var negate = false
    
    // MARK: - Initializers
    /**
     Creates a new instance of the Between Expression.
     
     - Parameters:
         - value: The value to test.
         - lowValue: The low range.
         - highValue: The high range.
         - negate: If `true`, negate the result of the test, else `false`.
    */
    public init(valueIn value: ADSQLExpression, lowValue: ADSQLExpression, highValue: ADSQLExpression, _ negate: Bool = false) {
        self.value = value
        self.lowValue = lowValue
        self.highValue = highValue
        self.negate = negate
    }
    
    /**
     Decodes the expression from an Instance Dictionary that has been read from a Swift Portable Object Notation (SPON) stream.
     - Parameter dictionary: A `ADInstanceDictionary` representing the values for the expression.
     */
    public required init(fromInstance dictionary: ADInstanceDictionary) {
        self.value = ADSQLLiteralExpression(value: "")
        self.lowValue = ADSQLLiteralExpression(value: "")
        self.highValue = ADSQLLiteralExpression(value: "")
        self.decode(fromInstance: dictionary)
    }
    
    // MARK: - Functions
    /**
     Evaluates the given expression and returns a result based on the data in the record passed in.
     - Parameter row: A `ADRecord` containing values to be evaluated against the expression.
     - Returns: The result of the evaluation.
     */
    @discardableResult public func evaluate(forRecord row: ADRecord? = nil) throws -> Any? {
        
        // Evaluate expressions
        let val = try value.evaluate(forRecord: row)
        let low = try lowValue.evaluate(forRecord: row)
        let high = try highValue.evaluate(forRecord: row)
        
        // Valid?
        if let v = val as? Float {
            if let v1 = low as? Float {
                if let v2 = high as? Float {
                    return (v >= v1 && v <= v2)
                }
            }
        }
        
        // Invalid
        throw ADSQLExecutionError.syntaxError(message: "Calling BETWEEN with invalid values.")
    }
    
    /**
     Encodes the expression into an Instance Dictionary for storage in a Swift Portable Object Notation (SPON) format.
     -Returns: The expression represented as an Instance Dictionary.
     */
    public func encode() -> ADInstanceDictionary {
        let dictionary = ADInstanceDictionary()
        
        // Save values
        dictionary.typeName = "Between"
        dictionary.storage["value"] = value.encode()
        dictionary.storage["lowValue"] = lowValue.encode()
        dictionary.storage["highValue"] = highValue.encode()
        dictionary.storage["negate"] = negate
        
        return dictionary
    }
    
    /**
     Decodes the expression from an Instance Dictionary that has been read from a Swift Portable Object Notation (SPON) stream.
     - Parameter dictionary: A `ADInstanceDictionary` representing the values for the expression.
     */
    public func decode(fromInstance dictionary: ADInstanceDictionary) {
        if let exp = dictionary.storage["value"] as? ADInstanceDictionary {
            value = ADSQLExpressionBuilder.build(fromInstance: exp)!
        }
        if let exp = dictionary.storage["lowValue"] as? ADInstanceDictionary {
            lowValue = ADSQLExpressionBuilder.build(fromInstance: exp)!
        }
        if let exp = dictionary.storage["highValue"] as? ADInstanceDictionary {
            highValue = ADSQLExpressionBuilder.build(fromInstance: exp)!
        }
        if let value = dictionary.storage["negate"] as? Bool {
            negate = value
        }
    }
}
