//
//  ADSQLColumnDefinition.swift
//  ActionControls
//
//  Created by Kevin Mullins on 10/24/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/**
 Holds information about a column definition read from a CREATE TABLE instruction when parsing a SQL statement.
 */
public struct ADSQLColumnDefinition {
    
    // MARK: - Properties.
    /// The column name.
    public var name: String = ""
    
    /// The optional column alias.
    public var alias: String = ""
    
    /// The type of information stored in the column as defined by a `ADSQLColumnType`.
    public var type: ADSQLColumnType = .noneType
    
    /// A list of optional constraints for the column.
    public var constraints: [ADSQLColumnConstraint] = []
    
    // MARK: - Initializers
    /// Creates a new instance of the column definition.
    public init() {
        
    }
    
    /// Creates a new instance of the column definition.
    /// - Parameter name: The name of the column to create.
    public init(columnName name: String) {
        self.name = name
    }
}
