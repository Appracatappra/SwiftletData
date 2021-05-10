//
//  ADSQLJoinClause.swift
//  ActionControls
//
//  Created by Kevin Mullins on 11/3/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/**
 Holds the source table or table group for a SQL SELECT statement. If the `type` is `none` this is a single table name and not a join between two (or more) tables.
 */
public class ADSQLJoinClause {
    
    // MARK: - Enumerations
    /// The type of join being created.
    public enum JoinType {
        /// This join represents an individual table name.
        case none
        
        /// The table is joined to another table where on any fields that have the same name and value.
        case natural
        
        /// This table is Left Outer Joined to another table.
        case leftOuter
        
        /// This table is Inner Joined to another table.
        case inner
        
        /// This table is Cross Joined to another table.
        case cross
    }
    
    // MARK: - Properties
    /// The name of the parent table in a join operation or a literal table name is no join is being performed and the `type` property's value is `none`.
    public var parentTable: String = ""
    
    /// The optional alias for the parent table.
    public var parentTableAlias: String = ""
    
    /// The name of the child table in a join operation of empty string if no join is being performed.
    public var childTable: String = ""
    
    /// The alias for the child table.
    public var childTableAlias: String = ""
    
    /// If the child table is part of a join, this represents its join clause.
    public var childJoin: ADSQLJoinClause?
    
    /// The type of join being performed.
    public var type: JoinType = .none
    
    /// Defines the conditions that two tables are joined on or `nil` if no join is being performed.
    public var onExpression: ADSQLExpression?
    
    /// A list of columns that are part of the join.
    public var columnList: [String] = []
}
