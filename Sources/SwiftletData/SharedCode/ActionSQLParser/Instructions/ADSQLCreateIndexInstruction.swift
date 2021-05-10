//
//  File.swift
//  ActionControls
//
//  Created by Kevin Mullins on 10/20/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/**
 Holds the information for a SQL CREATE INDEX instruction.
 */
public struct ADSQLCreateIndexInstruction: ADSQLInstruction {
    
    // Properties
    /// If `true` the index is unique, else `false`.
    public var makeUnique: Bool = false
    
    /// The name of the index being created.
    public var indexName: String = ""
    
    /// The name of the table that the index is being created on.
    public var tableName: String = ""
    
    /// The list of columns in the index.
    public var columnList: [String] = []
    
    /// The optional WHERE clause that controls which table rows are included in the Index.
    public var whereExpression: ADSQLExpression?
}
