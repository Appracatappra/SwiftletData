//
//  ADSQLConflictHandling.swift
//  ActionControls
//
//  Created by Kevin Mullins on 10/24/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/// Defines the type of conflict handling that can be applied to a column or table constraint.
public enum ADSQLConflictHandling {
    /// No conflict handling.
    case none
    
    /// Rollback the changes.
    case rollback
    
    /// Abort SQL statement execution.
    case abort
    
    /// Fail the execution.
    case fail
    
    /// Ignore the issue.
    case ignore
    
    /// Replace the value.
    case replace
}
