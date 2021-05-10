//
//  ADSQLColumnConstraint.swift
//  ActionControls
//
//  Created by Kevin Mullins on 10/24/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/**
 Holds information about a constraint applied to a Column Definition that has been parsed from a SQL CREATE TABLE instruction.
 */
public struct ADSQLColumnConstraint {
    
    // MARK: - Enumerations.
    /// Defines the type of column constraint.
    public enum ColumnConstraintType {
        /// The column is the primary key for the table in an ascending order.
        case primaryKeyAsc
        
        /// The column is the primary key for the table in a descending order.
        case primaryKeyDesc
        
        /// The column's value cannot be NULL.
        case notNull
        
        /// The column's value must be unique inside the table.
        case unique
        
        /// A custom constraint is being applied to the columns value.
        case check
        
        /// If this column is NULL, it will be replaced with this default value.
        case defaultValue
        
        /// The columns has a collation constraint.
        case collate
        
        /// The column value is a foreign key to another table's row.
        case foreignKey
    }
    
    // MARK: - Properties
    /// The type of the constraint.
    public var type: ColumnConstraintType = .primaryKeyAsc
    
    /// If the column is a PRIMARY KEY of the INTEGER type, is it automatically incremented when a new row is created in the table.
    public var autoIncrement: Bool = false
    
    /// Defines how conflicts should be handled for this column.
    public var conflictHandling: ADSQLConflictHandling = .none
    
    /// Holds the expression for a Check or Default Value constraint.
    public var expression: ADSQLExpression?
    
    // MARK: - Initializers
    /// Initializes a new instance of the Column Constraint.
    public init() {
        
    }
    
    /**
     Initializes a new instance of the Column Constraint.
     
     - Parameters:
         - type: The type of constraint being created.
         - expression: An expression for a Check or Default Value constraint.
    */
    public init(ofType type: ColumnConstraintType, withExpression expression: ADSQLExpression? = nil) {
        self.type = type
        self.expression = expression
    }
}
