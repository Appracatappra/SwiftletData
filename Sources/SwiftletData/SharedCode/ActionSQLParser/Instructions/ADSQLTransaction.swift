//
//  ADSQLTransaction.swift
//  ActionControls
//
//  Created by Kevin Mullins on 11/8/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/**
 Holds all information about a SQL BEGIN, COMMIT, END, ROLLBACK, SAVEPOINT or RELEASE instruction.
 */
public struct ADSQLTransactionInstruction: ADSQLInstruction {
    
    // MARK: - Enumerations
    /// Defines the type of transaction being performed.
    public enum Action {
        /// A begin deffered transaction.
        case beginDeferred
        
        /// A begin immediate transaction.
        case beginImmediate
        
        /// A begin exclusive transaction.
        case beginExclusive
        
        /// A commit (or end) transaction.
        case commit
        
        /// A rollback transaction.
        case rollback
        
        /// A create savepoint transaction.
        case savepoint
        
        /// A release savepoint transaction.
        case releaseSavepoint
    }
    
    // MARK: - Properties
    /// Defined the type of transaction.
    public var action: Action = .beginImmediate
    
    /// For ROLLBACK, SAVEPOINT and RELEASE transactions, defines the name of the save point.
    public var savepointName: String = ""
    
    // MARK: - Initializers
    /// Creates a new instance of the transaction.
    public init() {
        
    }
    
    /// Creates a new instance of the transaction.
    /// - Parameter forAction: The type of transaction being created.
    public init(forAction: Action) {
        self.action = forAction
    }
}
