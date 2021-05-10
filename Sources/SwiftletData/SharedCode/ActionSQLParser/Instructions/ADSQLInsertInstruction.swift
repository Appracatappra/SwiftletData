//
//  ADSQLInsertInstruction.swift
//  ActionControls
//
//  Created by Kevin Mullins on 11/8/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/**
 Holds all information about a SQL INSERT instruction.
 */
public struct ADSQLInsertInstruction: ADSQLInstruction {
    
    // MARK: - Enumerations
    // Defines the type of insert action.
    public enum Action {
        /// Attempt to insert a new row.
        case insert
        /// Attempt to replace an existing row.
        case replace
        
        /// Either insert a new or replace an existing row.
        case insertOrReplace
        
        /// Attempt to insert a new row and rollback if the row cannot be created.
        case insertOrRollback
        
        /// Attempt to insert a new row and abort if the row cannot be created.
        case insertOrAbort
        
        /// Attempt to insert a new row and fail if the row cannot be created.
        case insertOrFail
        
        /// Attempt to insert a new row and ignore the issue if the row cannot be created.
        case insertOrIgnore
    }
    
    // MARK: - Properties
    /// The type of insert to perform.
    public var action: Action = .insert
    
    /// The name of the table that a row is being inserted into.
    public var tableName: String = ""
    
    /// The name of the columns being inserted into the table row.
    public var columnNames: [String] = []
    
    /// The values to insert into the table row.
    public var values: [ADSQLExpression] = []
    
    /// An optional SELECT statement used to populate the new table row(s).
    public var selectStatement: ADSQLSelectInstruction?
    
    /// If `true`, the new row should be created with the default value of the table.
    public var defaultValues: Bool = false
}
