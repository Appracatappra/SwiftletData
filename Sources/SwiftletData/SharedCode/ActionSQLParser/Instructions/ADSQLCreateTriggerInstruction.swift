//
//  ADSQLCreateTriggerInstruction.swift
//  ActionControls
//
//  Created by Kevin Mullins on 10/20/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/**
 Holds information about a SQL CREATE TRIGGER instruction.
 */
public struct ADSQLCreateTriggerInstruction: ADSQLInstruction {
    
    // MARK: - Enumerations
    /// Defines when a triger should be fired.
    public enum WhenToTrigger {
        /// The trigger will execute before the SQL statement.
        case before
        
        /// The trigger will execute after the SQL statement.
        case after
        
        /// The trigger will execute instead of the SQL statement.
        case insteadOf
    }
    
    /// Defines the trigger's type.
    public enum TriggerType {
        /// The triger will fire on delete statements.
        case delete
        
        /// The trigger will fire on insert statements.
        case insert
        
        /// The trigger will fire on update statements.
        case updateOf
    }
    
    // MARK: - Properties
    /// The name of the trigger being created.
    public var triggerName: String = ""
    
    /// Defines when the trigger should fire.
    public var triggerWhen: WhenToTrigger = .before
    
    /// Defines the type of trigger being created.
    public var triggerType: TriggerType = .delete
    
    /// Defines the list of columns that form the trigger.
    public var columnList: [String] = []
    
    /// Defines the table that the trigger is being created against.
    public var tableName: String = ""
    
    /// If `true`, the trigger will execute after each table row being modified by a SQL statement.
    public var forEachRow: Bool = false
    
    /// The expression defining when the trigger will fire.
    public var whenExpression: ADSQLExpression?
    
    /// A list of instruction to run when the trigger fires.
    public var instructions: [ADSQLInstruction] = []
    
}
