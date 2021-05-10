//
//  ADDataProviderError.swift
//  ActionControls
//
//  Created by Kevin Mullins on 9/18/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/// Defines the type of errors that can arise when working with a data provider that conforms to the `ADDataProvider` protocol.
public enum ADDataProviderError: Error {
    /// The data provider is attempting to work with a datasource before it has been opened.
    case dataSourceNotOpen
    
    /// Failed to copy a writable version of the database source from the app's bundle to the documents directory. `message` contains the details of the given failure.
    case dataSourceCopyFailed(message: String)
    
    /// Unable to open the data source from the given location  or with the given name.
    case dataSourceNotFound
    
    /// The data provider was unable to open the given data source.
    case unableToOpenDataSource
    
    /// The data provider failed to delete the data source.
    case failedToDeleteSource
    
    /// The data provider does not have the requested table name on file. `message` contains the details of the given failure.
    case tableNotFound(message: String)
    
    /// The data provider was unable to prepare the SQL statement for execution while binding the passed set of parameters. `message` contains the details of the given failure.
    case failedToPrepareSQL(message: String)
    
    /// The number of parameters specified in the SQL statement did not match the number of parameters passed to the data provider.
    case parameterCountMismatch
    
    /// The data provider was unable to bind a given parameter to the SQL statement. `message` contains the details of the given failure.
    case unableToBindParameter(message: String)
    
    /// The data provider was unable to create the requested table in the data source. `message` contains the details of the given failure.
    case failedToCreateTable(message: String)
    
    /// The data provider was unable to execute the given SQL statement. `message` contains the details of the given failure.
    case failedToExecuteSQL(message: String)
    
    /// The data provider was unable to update the given table schema to the new version. `message` contains the details of the given failure.
    case failedToUpdateTableSchema(message: String)
    
    /// The data provider was unable to fetch the requested row(s) from the data source. `message` contains the details of the given failure.
    case unableToGetRows(message: String)
    
    /// The data provider was unable to complete the given batch update command. `message` contains the details of the given failure.
    case batchUpdateFailed(message: String)
    
    /// While attempting to create or update a table schema, the data provider encountered a `nil` value. Use either the `register` or `update` functions with a fully populated **default value class instance** (with all values set to a default, non-nil value) to create or update the table schema. `message` contains the details of the given failure.
    case missingRequiredValue(message: String)
    
    /// While reading a value from a CloudKit record, the data provider was unable to move that value forward.
    case unableToConvertValue(message: String)
    
    /// No further rows are remaining from a call to `getRows`.
    case noRowsRemaining
}
