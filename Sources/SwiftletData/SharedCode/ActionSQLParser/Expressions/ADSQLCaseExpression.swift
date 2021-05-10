//
//  ADSQLCaseExpression.swift
//  ActionControls
//
//  Created by Kevin Mullins on 10/26/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/// Defines a case clause used in a SQL instruction.
public class ADSQLCaseExpression: ADSQLExpression {
    
    // MARK: - Properties
    /// The value to compare.
    public var compareValue: ADSQLExpression
    
    /// The list of value to compare against.
    public var toValues: [ADSQLWhenExpression] = []
    
    /// The default value to return when no values match.
    public var defaultValue: ADSQLExpression
    
    // MARK: - Initializers
    /**
     Creates a new Case Expression instance.
     
     - Parameters:
         - compareValue: The value to compare.
         - toValues: The list of value to compare against.
         - defaultValue: The default value to return if none of the values match.
    */
    public init(compareValue: ADSQLExpression, toValues: [ADSQLWhenExpression], defaultValue: ADSQLExpression) {
        self.compareValue = compareValue
        self.toValues = toValues
        self.defaultValue = defaultValue
    }
    
    /**
     Decodes the expression from an Instance Dictionary that has been read from a Swift Portable Object Notation (SPON) stream.
     - Parameter dictionary: A `ADInstanceDictionary` representing the values for the expression.
     */
    public required init(fromInstance dictionary: ADInstanceDictionary) {
        self.compareValue = ADSQLLiteralExpression(value: "")
        self.defaultValue = ADSQLLiteralExpression(value: "")
        self.decode(fromInstance: dictionary)
    }
    
    // MARK: - Functions
    /**
     Evaluates the given expression and returns a result based on the data in the record passed in.
     - Parameter row: A `ADRecord` containing values to be evaluated against the expression.
     - Returns: The result of the evaluation.
     */
    @discardableResult public func evaluate(forRecord row: ADRecord? = nil) throws -> Any? {
        var values: [String] = []
        var options: [String:Any] = [:]
        
        // Evalue expressions
        let val = try compareValue.evaluate(forRecord: row)
        for item in toValues {
            let result = try item.evaluate(forRecord: row)
            if let v = result as? String {
                values.append(v)
                options[v] = try item.thenValue.evaluate(forRecord: row)
            } else {
                throw ADSQLExecutionError.syntaxError(message: "Invalid value in IN clause.")
            }
        }
        
        // Compare?
        if let v1 = val as? String {
            for item in values {
                if v1 == item {
                    return options[item]
                }
            }
            return try defaultValue.evaluate(forRecord:row)
        }
        
        // Error
        throw ADSQLExecutionError.syntaxError(message: "Malformed CASE...WHEN statement.")
    }
    
    /**
     Encodes the expression into an Instance Dictionary for storage in a Swift Portable Object Notation (SPON) format.
     -Returns: The expression represented as an Instance Dictionary.
     */
    public func encode() -> ADInstanceDictionary {
        let dictionary = ADInstanceDictionary()
        let array = ADInstanceArray()
        
        // Save parameters into the array
        for item in toValues {
            array.storage.append(item.encode())
        }
        
        // Save values
        dictionary.typeName = "Case"
        dictionary.storage["compareValue"] = compareValue.encode()
        dictionary.storage["toValues"] = array
        dictionary.storage["defaultValue"] = defaultValue.encode()
        
        return dictionary
    }
    
    /**
     Decodes the expression from an Instance Dictionary that has been read from a Swift Portable Object Notation (SPON) stream.
     - Parameter dictionary: A `ADInstanceDictionary` representing the values for the expression.
     */
    public func decode(fromInstance dictionary: ADInstanceDictionary) {
        if let exp = dictionary.storage["compareValue"] as? ADInstanceDictionary {
            compareValue = ADSQLExpressionBuilder.build(fromInstance: exp)!
        }
        if let array = dictionary.storage["toValues"] as? ADInstanceArray {
            for item in array.storage {
                if let exp = item as? ADInstanceDictionary {
                    if let expression = ADSQLExpressionBuilder.build(fromInstance: exp) as? ADSQLWhenExpression {
                        toValues.append(expression)
                    }
                }
            }
        }
        if let exp = dictionary.storage["defaultValue"] as? ADInstanceDictionary {
            defaultValue = ADSQLExpressionBuilder.build(fromInstance: exp)!
        }
    }
}
