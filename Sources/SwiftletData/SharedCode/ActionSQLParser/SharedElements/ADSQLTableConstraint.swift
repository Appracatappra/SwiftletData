//
//  ADSQLTableConstraint.swift
//  ActionControls
//
//  Created by Kevin Mullins on 11/3/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/**
 Holds information about a constraint being applied to table from a CREATE TABLE SQL instruction.
 */
public struct ADSQLTableConstraint {
    
    // MARK: - Enumerations
    /// The type of the constraint.
    public enum TableConstraintType {
        /// A `PrimaryKey(...)` constraint.
        case primaryKey
        
        /// A unique value constraint.
        case unique
        
        /// A custom constraint.
        case check
        
        /// A value in the table that is a key to a row in a foreign table.
        case foreignKey
    }
    
    // MARK: - Properties
    /// The type of the table constraint.
    public var type: TableConstraintType = .primaryKey
    
    /// The type of conflict handling for this table constraint.
    public var conflictHandling: ADSQLConflictHandling = .none
    
    /// The value for a Check constraint.
    public var expression: ADSQLExpression?
    
    /// A list of columns that this constraint effects.
    public var columnList: [String] = []
    
    // MARK: - Initializers
    /// Initializes a new instance of the table constraint.
    public init() {
        
    }
    
    /**
     Initializes a new instance of the table constraint.
     
     - Parameters:
         - typeOf: The type of constraint being created.
         - expression: The value for a Check type of constraint.
    */
    public init(typeOf: TableConstraintType, withExpression expression: ADSQLExpression? = nil) {
        self.type = typeOf
        self.expression = expression
    }
}
