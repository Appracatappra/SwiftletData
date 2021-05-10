//
//  ADSQLExpression.swift
//  ActionControls
//
//  Created by Kevin Mullins on 10/24/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/// Holds information about a expression parsed from a SQL instruction.
public protocol ADSQLExpression {
    
    /**
     Decodes the expression from an Instance Dictionary that has been read from a Swift Portable Object Notation (SPON) stream.
     - Parameter dictionary: A `ADInstanceDictionary` representing the values for the expression.
     */
    init(fromInstance dictionary: ADInstanceDictionary)
    
    /**
     Evaluates the given expression and returns a result based on the data in the record passed in.
     - Parameter record: A `ADRecord` containing values to be evaluated against the expression.
     - Returns: The result of the evaluation.
    */
    @discardableResult func evaluate(forRecord record: ADRecord?) throws -> Any?
    
    /**
     Encodes the expression into an Instance Dictionary for storage in a Swift Portable Object Notation (SPON) format.
     -Returns: The expression represented as an Instance Dictionary.
    */
    func encode() -> ADInstanceDictionary
    
    /**
     Decodes the expression from an Instance Dictionary that has been read from a Swift Portable Object Notation (SPON) stream.
     - Parameter dictionary: A `ADInstanceDictionary` representing the values for the expression.
    */
    func decode(fromInstance dictionary: ADInstanceDictionary)
}
