//
//  ADSQLWhenExpression.swift
//  ActionControls
//
//  Created by Kevin Mullins on 10/26/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/// Defines a when clause using in a CASE clause in a SQL instruction.
public class ADSQLWhenExpression: ADSQLExpression {
    
    // MARK: - Properies
    /// The value used to trigger the expression.
    public var whenValue: ADSQLExpression
    
    /// The value returned when triggered.
    public var thenValue: ADSQLExpression
    
    // MARK: - Initializers
    public init(whenValue: ADSQLExpression, thenValue: ADSQLExpression) {
        self.whenValue = whenValue
        self.thenValue = thenValue
    }
    
    /**
     Decodes the expression from an Instance Dictionary that has been read from a Swift Portable Object Notation (SPON) stream.
     - Parameter dictionary: A `ADInstanceDictionary` representing the values for the expression.
     */
    public required init(fromInstance dictionary: ADInstanceDictionary) {
        self.whenValue = ADSQLLiteralExpression(value: "")
        self.thenValue = ADSQLLiteralExpression(value: "")
        self.decode(fromInstance: dictionary)
    }
    
    // MARK: - Functions
    /**
     Evaluates the given expression and returns a result based on the data in the record passed in.
     - Parameter row: A `ADRecord` containing values to be evaluated against the expression.
     - Returns: The result of the evaluation.
     */
    @discardableResult public func evaluate(forRecord row: ADRecord? = nil) throws -> Any? {
        return try whenValue.evaluate(forRecord:row)
    }
    
    /**
     Encodes the expression into an Instance Dictionary for storage in a Swift Portable Object Notation (SPON) format.
     -Returns: The expression represented as an Instance Dictionary.
     */
    public func encode() -> ADInstanceDictionary {
        let dictionary = ADInstanceDictionary()
        
        // Save values
        dictionary.typeName = "When"
        dictionary.storage["whenValue"] = whenValue.encode()
        dictionary.storage["thenValue"] = thenValue.encode()
        
        return dictionary
    }
    
    /**
     Decodes the expression from an Instance Dictionary that has been read from a Swift Portable Object Notation (SPON) stream.
     - Parameter dictionary: A `ADInstanceDictionary` representing the values for the expression.
     */
    public func decode(fromInstance dictionary: ADInstanceDictionary) {
        if let exp = dictionary.storage["whenValue"] as? ADInstanceDictionary {
            whenValue = ADSQLExpressionBuilder.build(fromInstance: exp)!
        }
        if let exp = dictionary.storage["thenValue"] as? ADInstanceDictionary {
            thenValue = ADSQLExpressionBuilder.build(fromInstance: exp)!
        }
    }
}
