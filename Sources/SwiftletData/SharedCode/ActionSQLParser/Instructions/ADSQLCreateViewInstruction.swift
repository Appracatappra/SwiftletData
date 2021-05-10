//
//  ADSQLCreateViewInstruction.swift
//  ActionControls
//
//  Created by Kevin Mullins on 10/20/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/**
 Holds all the information for a SQL CREATE VIEW instruction.
 */
public struct ADSQLCreateViewInstruction: ADSQLInstruction {
    
    // MARK: - Properties
    /// The name of the view being created.
    public var viewName: String = ""
    
    /// The list of columns in the view.
    public var columnList: [String] = []
    
    /// The SQL SELECT statement used to populate the view.
    public var selectStatement: ADSQLSelectInstruction?
    
}
