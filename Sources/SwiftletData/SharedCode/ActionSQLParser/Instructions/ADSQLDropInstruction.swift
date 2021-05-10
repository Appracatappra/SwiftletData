//
//  ADSQLDropInstruction.swift
//  ActionControls
//
//  Created by Kevin Mullins on 11/8/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/**
 Holds all information about a SQL DROP instruction.
 */
public struct ADSQLDropInstruction: ADSQLInstruction {
    
    // MARK: - Enumerations
    /// Defines the type of object being removed from the data source.
    public enum Action {
        /// Drops an index.
        case index
        
        /// Drops a table.
        case table
        
        /// Drops a trigger.
        case trigger
        
        /// Drops a view.
        case view
    }
    
    // MARK: - Properties
    /// Defines what is being removed from the data source.
    public var action: Action = .view
    
    /// If `true`, the item will only be dropped if it exists in the data source.
    public var ifExists: Bool = false
    
    /// The name of the item being removed from the data source.
    public var itemName: String = ""
}
