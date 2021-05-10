//
//  ADSQLResultColumn.swift
//  ActionControls
//
//  Created by Kevin Mullins on 11/3/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/**
 Holds a result column definition for a SELECT SQL statement.
 */
public struct ADSQLResultColumn {
    
    // MARK: - Properties
    /// The value of the column as either a calculated expression or a literal column name.
    public var expression: ADSQLExpression!
    
    /// An optional alias for the column value returned.
    public var columnAlias: String = ""
    
    public init(with expression: ADSQLExpression) {
        self.expression = expression
    }
}
