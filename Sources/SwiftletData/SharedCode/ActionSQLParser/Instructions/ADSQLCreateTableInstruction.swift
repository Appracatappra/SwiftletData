//
//  ADSQLCreateTableInstruction.swift
//  ActionControls
//
//  Created by Kevin Mullins on 10/20/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/**
 Holds information about a SQL CREATE TABLE instruction.
 */
public struct ADSQLCreateTableInstruction: ADSQLInstruction {
    
    // MARK: - Properties
    /// The name of the table being created.
    public var name: String = ""
    
    /// If `true` this is a temporary table, else `false`.
    public var isTemporary: Bool = false
    
    /// If `true` the table should only be created if it doesn't already exist, else `false`.
    public var ifNotExists: Bool = false
    
    /// A list of columns being created in the table.
    public var columns: [ADSQLColumnDefinition] = []
    
    /// An optional list of constraints being applied to the table.
    public var constraints: [ADSQLTableConstraint] = []
    
    /// If `true` the table does not have an internal row id, else `false`.
    public var withoutRowID: Bool = false
    
    /// If this is a CREATE TABLE name AS SELECT... statement, this property holds the SELECT statement.
    public var selectStatement: ADSQLSelectInstruction?
    
    // MARK: - Initializers
    /// Initializes a new instance of the Create Table Instruction.
    public init() {
        
    }
    
    /**
     Initializes a new instance of the Create Table Instruction.
     
     - Parameters:
         - name: The name of the table being created.
         - isTemporary: Is a temporary table being created.
         - ifNotExists: Should the table only be created if it doesn't already exist?
    */
    public init(tableName name: String, _ isTemporary: Bool, _ ifNotExists: Bool) {
        self.name = name
        self.isTemporary = isTemporary
        self.ifNotExists = ifNotExists
    }
}
