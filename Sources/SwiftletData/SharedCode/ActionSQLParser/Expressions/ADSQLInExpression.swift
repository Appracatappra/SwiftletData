//
//  ADSQLInExpression.swift
//  ActionControls
//
//  Created by Kevin Mullins on 10/26/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/// Defines a in expression used in a SQL instruction to see if a value is in the list of give values.
public class ADSQLInExpression: ADSQLExpression {
    
    // MARK: - Properties
    ///  The value to test.
    public var value: ADSQLExpression
    
    /// The list of possible values.
    public var list: [ADSQLExpression] = []
    
    /// If `true`, negate the results of the test, else `false`.
    public var negate = false
    
    // MARK: - Initializers
    /**
     Creates a new In Expression instance.
     
     - Parameters:
     - value: The value to test.
     - list: The list of possible values.
     - negate: If `true`, negate the results of the test, else `false`
    */
    public init(value: ADSQLExpression, inList list: [ADSQLExpression], _ negate: Bool = false) {
        self.value = value
        self.list = list
        self.negate = negate
    }
    
    /**
     Decodes the expression from an Instance Dictionary that has been read from a Swift Portable Object Notation (SPON) stream.
     - Parameter dictionary: A `ADInstanceDictionary` representing the values for the expression.
     */
    public required init(fromInstance dictionary: ADInstanceDictionary) {
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
        var values: [String] = []
        
        // Evalue expressions
        let val = try value.evaluate(forRecord: row)
        for item in list {
            let result = try item.evaluate(forRecord: row)
            if let v = result as? String {
                values.append(v)
            } else {
                throw ADSQLExecutionError.syntaxError(message: "Invalid value in IN clause.")
            }
        }
        
        // Compariable?
        if let v1 = val as? String {
            // In set?
            for option in values {
                if v1 == option {
                    return true
                }
            }
            
            // Not in set
            return false
        }
        
        // Error
        throw ADSQLExecutionError.syntaxError(message: "Malformed IN clause.")
    }
    
    /**
     Encodes the expression into an Instance Dictionary for storage in a Swift Portable Object Notation (SPON) format.
     -Returns: The expression represented as an Instance Dictionary.
     */
    public func encode() -> ADInstanceDictionary {
        let dictionary = ADInstanceDictionary()
        let array = ADInstanceArray()
        
        // Save parameters into the array
        for item in list {
            array.storage.append(item.encode())
        }
        
        // Save values
        dictionary.typeName = "In"
        dictionary.storage["value"] = value.encode()
        dictionary.storage["list"] = array
        
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
        if let array = dictionary.storage["list"] as? ADInstanceArray {
            for item in array.storage {
                if let exp = item as? ADInstanceDictionary {
                    if let expression = ADSQLExpressionBuilder.build(fromInstance: exp) {
                        list.append(expression)
                    }
                }
            }
        }
    }
}
