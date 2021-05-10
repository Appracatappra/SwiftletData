//
//  ADSQLDeleteInstruction.swift
//  ActionControls
//
//  Created by Kevin Mullins on 11/8/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/**
 Holds all information about a SQL DELETE instruction.
 */
public struct ADSQLDeleteInstruction: ADSQLInstruction {
    
    // MARK: - Properties
    /// The name of the table that rows will be deleted from.
    public var tableName: String = ""
    
    /// An optional WHERE clause used to determine the rows of the table to delete. If `nil` all rows in the table will be deleted.
    public var whereExpression: ADSQLExpression?
}
