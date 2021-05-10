//
//  ADSQLExecutionError.swift
//  ActionControls
//
//  Created by Kevin Mullins on 11/9/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/// Defines the errors that can be thrown when executing SQL statements.
public enum ADSQLExecutionError: Error {
    /// The table already exists inside of the data store. `message` contains the details of the given failure.
    case duplicateTable(message: String)
    
    /// The requested SQL command isn't supported by Action Data or then current Data Provider. `message` contains the details of the given failure.
    case unsupportedCommand(message: String)
    
    /// The requested SQL command isn't valid in the given context. `message` contains the details of the given failure.
    case invalidCommand(message: String)
    
    /// The data store doesn't contain the given table. `message` contains the details of the given failure.
    case unknownTable(message: String)
    
    /// The data store doesn't contain the given column in the given table. `message` contains the details of the given failure.
    case unknownColumn(message: String)
    
    /// The data store could not execute the SQL command because it contained a syntax error. `message` contains the details of the given failure.
    case syntaxError(message: String)
    
    /// The ADRecord is not valid for the given data table. `message` contains the details of the given failure.
    case invalidRecord(message: String)
    
    /// A record with the same primary key already exists in the table. `message` contains the details of the given failure.
    case duplicateRecord(message: String)
    
    /// An attempt to insert or update a record failed due to a CHECK constraint. `message` contains the details of the given failure.
    case failedCheckConstraint(message: String)
    
    /// The SELECT clause in a CREATE statement returned no rows. `message` contains the details of the given failure.
    case noRowsReturned(message: String)
    
    /// The number of parameters (specified by a `?` in the SQL statement) did not match the number of parameters provided. `message` contains the details of the given failure.
    case unevenNumberOfParameters(message: String)
}
