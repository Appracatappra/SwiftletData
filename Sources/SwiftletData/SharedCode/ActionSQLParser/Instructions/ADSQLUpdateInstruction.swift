//
//  ADSQLUpdateInstruction.swift
//  ActionControls
//
//  Created by Kevin Mullins on 11/8/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/**
 Holds all of the information for a SQL UPDATE instruction.
 */
public struct ADSQLUpdateInstruction: ADSQLInstruction {
    
    // MARK: - Enumerations
    // Defines the type of update to be performed.
    public enum Action {
        /// Attempt to update a row in the table.
        case update
        
        /// Attempt to update a row in the table and rollback if unable to update.
        case updateOrRollback
        
        /// Attempt to update a row in the table and abort if unable to update.
        case updateOrAbort
        
        /// Attempt to update or replace a row in the table.
        case updateOrReplace
        
        /// Attempt to update a row in the table and fail if unable to update.
        case updateOrFail
        
        /// Attempt to update a row in the table and ignore the issue if unable to update.
        case updateOrIgnore
    }
    
    // MARK: - Properties
    /// The type of update to perform.
    public var action: Action = .update
    
    /// The name of the table being updated.
    public var tableName: String = ""
    
    /// A list of columns and values being written to the row.
    public var setClauses: [ADSQLSetClause] = []
    
    /// An optional expression controlling the rows to update.
    public var whereExpression: ADSQLExpression?
    
}
