//
//  ADSQLSelectInstruction.swift
//  ActionControls
//
//  Created by Kevin Mullins on 11/3/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/**
 Holds all information about a SQL SELECT instruction.
 */
public struct ADSQLSelectInstruction: ADSQLInstruction {
    
    // MARK: - Properties
    /// If `true`, a distince set of values will be returned, else `false`.
    public var distinct: Bool = false
    
    /// The list of columns returned by this select statement.
    public var columns: [ADSQLResultColumn] = []
    
    /// The source table (or tables) that the columns are read from.
    public var fromSouce: ADSQLJoinClause = ADSQLJoinClause()
    
    /// The WHERE clause defining which table rows should be returned. If this expression if `nil`, all rows will be returned.
    public var whereExpression: ADSQLExpression?
    
    /// An optional GROUP BY clause used to group the results of the SELECT statement.
    public var groupByColumns: [String] = []
    
    /// An optional HAVING clause to control when specific columns should be grouped.
    public var havingExpression: ADSQLExpression?
    
    /// An optional group of columns used to sort the resulting table rows.
    public var orderBy: [ADSQLOrderByClause] = []
    
    /// Defines the maximum number of rows returned. If `-1`, all rows will be returned.
    public var limit: Int = -1
    
    /// Defines an offest from the first row to start returning rows for. If `-1`, the results start with the first row.
    public var offset: Int = -1
}
