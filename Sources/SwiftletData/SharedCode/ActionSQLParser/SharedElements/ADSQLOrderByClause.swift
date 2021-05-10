//
//  ADSQLOrderByClause.swift
//  ActionControls
//
//  Created by Kevin Mullins on 11/8/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/**
 Holds information about a result ordering statement from a SQL SELECT statement.
 */
public struct ADSQLOrderByClause {
    
    // MARK: - Enumerations
    /// The direction of the column sort.
    public enum Order {
        /// Sort values in ascending order.
        case ascending
        
        /// Sort values in a descending order.
        case descending
    }
    
    // MARK: - Properties
    /// The name of the column used to order the results.
    public var columnName: String
    
    /// The optional colation name.
    public var collationName: String = ""
    
    /// The sort or for the results.
    public var order: Order = .ascending
    
    // MARK: - Initializers
    public init(on: String) {
        self.columnName = on
    }
    
}
