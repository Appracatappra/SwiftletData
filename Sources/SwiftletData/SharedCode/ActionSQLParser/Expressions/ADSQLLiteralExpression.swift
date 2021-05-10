//
//  ADSQLLiteralExpression.swift
//  ActionControls
//
//  Created by Kevin Mullins on 10/24/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/// Defines a literal expression used in a SQL instruction such as a column name, integer value or string constant value.
public class ADSQLLiteralExpression: ADSQLExpression {
    
    // MARK: - Properties
    /// Defines the value of the literal.
    public var value: String = ""
    
    // MARK: - Initializers
    /// Creates a new literal expression.
    /// - Parameter value: The value of the expression.
    public init(value: String) {
        self.value = value
    }
    
    /**
     Decodes the expression from an Instance Dictionary that has been read from a Swift Portable Object Notation (SPON) stream.
     - Parameter dictionary: A `ADInstanceDictionary` representing the values for the expression.
     */
    public required init(fromInstance dictionary: ADInstanceDictionary) {
        self.decode(fromInstance: dictionary)
    }
    
    // MARK: - Functions
    /**
     Evaluates the given expression and returns a result based on the data in the record passed in.
     - Parameter row: A `ADRecord` containing values to be evaluated against the expression.
     - Returns: The result of the evaluation.
     */
    @discardableResult public func evaluate(forRecord row: ADRecord? = nil) throws -> Any? {
        
        // Attempt to cast type based on what is stored in the expression
        if let val = Int(value) {
            return val
        } else if let val = Float(value) {
            return val
        }
        
        // Boolean value
        let val = value.lowercased()
        if "true,false,on,off,yes,no".contains(val) {
            switch val {
            case "true", "on", "yes":
                return true
            default:
                return false
            }
        }
        
        // Specifying a table column?
        if let record = row {
            if record.keys.contains(value) {
                // Yes, return the column from the record
                return record[value]
            }
        }
        
        // Return value as-is
        return value
    }
    
    /**
     Encodes the expression into an Instance Dictionary for storage in a Swift Portable Object Notation (SPON) format.
     -Returns: The expression represented as an Instance Dictionary.
     */
    public func encode() -> ADInstanceDictionary {
        let dictionary = ADInstanceDictionary()
        
        // Save values
        dictionary.typeName = "Literal"
        dictionary.storage["value"] = value
        
        return dictionary
    }
    
    /**
     Decodes the expression from an Instance Dictionary that has been read from a Swift Portable Object Notation (SPON) stream.
     - Parameter dictionary: A `ADInstanceDictionary` representing the values for the expression.
     */
    public func decode(fromInstance dictionary: ADInstanceDictionary) {
        value = dictionary.storage["value"] as! String
    }
}
