//
//  ADSQLSetClause.swift
//  ActionControls
//
//  Created by Kevin Mullins on 11/8/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/**
 Holds information about a value that is being written into a table's column from a SQL UPDATE statement.
 */
public struct ADSQLSetClause {
    
    // MARK: - Properties
    /// The name of the column getting the new value.
    public var columnName: String = ""
    
    /// The value being written to the  column.
    public var expression: ADSQLExpression?
    
}
