//
//  ADSQLExpressionBuilder.swift
//  ActionControls
//
//  Created by Kevin Mullins on 11/22/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/**
 Helper class to create a `ADSQLExpression` from a `ADInstanceDictionary` assembled from a Swift Portable Object Notation (SPON) data stream.
 */
public class ADSQLExpressionBuilder {
    
    /**
     Takes an Instance Dictionary representing an expression read from a Swift Portable Object Notation (SPON) data stream and attempts to return an Action Data Expression.
     
     - Parameter dictionary: A `ADInstanceDictionary` to convert to an expression.
     - Returns: A `ADSQLExpression` if the Instance Dictionary can be converted, else returns `nil`.
    */
    public static func build(fromInstance dictionary: ADInstanceDictionary) -> ADSQLExpression? {
        
        // Take action based on the type of expression
        switch dictionary.typeName {
        case "Literal":
            return ADSQLLiteralExpression(fromInstance: dictionary)
        case "Unary":
            return ADSQLUnaryExpression(fromInstance: dictionary)
        case "Binary":
            return ADSQLBinaryExpression(fromInstance: dictionary)
        case "Function":
            return ADSQLFunctionExpression(fromInstance: dictionary)
        case "Between":
            return ADSQLBetweenExpression(fromInstance: dictionary)
        case "In":
            return ADSQLInExpression(fromInstance: dictionary)
        case "When":
            return ADSQLWhenExpression(fromInstance: dictionary)
        case "ForeignKey":
            return ADSQLForeignKeyExpression(fromInstance: dictionary)
        default:
            // No object specified
            return nil
        }
        
    }
    
}
