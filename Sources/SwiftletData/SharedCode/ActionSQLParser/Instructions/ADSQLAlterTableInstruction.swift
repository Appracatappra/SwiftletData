//
//  ADSQLAlterTableInstruction.swift
//  ActionControls
//
//  Created by Kevin Mullins on 11/30/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/**
 Holds the information for a SQL ALTER TABLE instruction.
 */
public struct ADSQLAlterTableInstruction: ADSQLInstruction {

    // MARK: - Properties
    /// The name of the table being modified.
    public var name: String = ""
    
    /// If renaming the table, this will be the table's new name.
    public var renameTo: String = ""
    
    /// The definition of a columns being added.
    public var column: ADSQLColumnDefinition?
}
