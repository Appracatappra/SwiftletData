//
//  ADSQLParser.swift
//  ActionControls
//
//  Created by Kevin Mullins on 10/20/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation
import SwiftletUtilities

/**
 Parses a SQL statement into an Action Data SQL Document Object Model (DOM). This parser currently supports a subset of SQL commands as defined by SQLite. for example:
 
 ```swift
 let sql = """
 CREATE TABLE IF NOT EXISTS parts
 (
     part_id           INTEGER   PRIMARY KEY,
     stock             INTEGER   DEFAULT 0   NOT NULL,
     description       TEXT      CHECK( description != '' )    -- empty strings not allowed
 );
 """
 
 let instructions = try ADSQLParser.parse(sql)
 print(instructions)
 ```
 */
public class ADSQLParser {
    
    // MARK: - Enumerations
    /// Defines the state of the current parse operation.
    private enum parseState {
        /// Seeking the start of a SQL command
        case seekCommand
        
        /// Creating an index, table, trigger, view or virtual table.
        case creating
        
        /// Creating an index.
        case creatingIndex
        
        /// Creating a new table.
        case creatingTable
        
        /// Creating a new trigger.
        case creatingTrigger
        
        /// Creating a new view.
        case creatingView
        
        /// Seeking column definitions.
        case seekColumnDef
        
        /// Seeking a type definition.
        case seekType
        
        /// Seeking a constraint.
        case seekConstraint
        
        /// Creating a constraint.
        case inConstraint
        
        /// Building a conflict clause.
        case inConflictClause
        
        /// Seeking WHEN clause inside of a CASE statement.
        case seekCaseWhen
        
        /// Seeking THEN clause inside of a CASE statement.
        case seekCaseThen
        
        /// Seeking END clause inside of a CASE statement.
        case seekCaseEnd
        
        /// Seeking list of column names.
        case seekColumnList
        
        /// Inside list of column names.
        case inColumnList
        
        /// Seeking table constraint.
        case seekTableConstraint
        
        /// In table constraint.
        case inTableConstraint
        
        // Seeking Order By clause.
        case seekOrderBy
        
        // In an Order By clause.
        case inOrderBy
    }
    
    // MARK: - Initializers
    /// Creates a new SQL Parses instance.
    init() {
        
    }
    
    // MARK: - Functions
    /**
     Attempts to parse the given string into an Action Data SQL DOM. This parser currently supports a subset of SQL commands as defined by SQLite. For exmaple:
     
     ```swift
     let sql = "SELECT * FROM parts WHERE part_id = 10"
     
     let instructions = try ADSQLParser.parse(sql)
     print(instructions)
     ```
     
     - Parameter sql: The SQL instruction to parse.
     - Returns: A list of `ADSQLInstruction` instances representing the DOM for the given SQL instruction.
     - Remark: This function will throw a `ADSQLParseError` if it encounters an issue while parsing the input string.
    */
    public static func parse(_ sql: String) throws -> [ADSQLInstruction] {
        var instructions: [ADSQLInstruction] = []
        var state = parseState.seekCommand
        var makeUnique = false
        var ifNotExists = false
        var makeTemporary = false
        
        // Parse the input string
        try ADSQLParseQueue.shared.parse(sql)
        
        // Interpret parse queue
        while ADSQLParseQueue.shared.count > 0 {
            let element = ADSQLParseQueue.shared.pop()
            
            // Get next keyword
            if let keyword = ADSQLKeyword.get(fromString: element) {
                // Take action based on the given keyword
                switch(keyword) {
                case .semicolon:
                    // Hit the command separator
                    state = .seekCommand
                case .alterKey:
                    switch(state) {
                    case .seekCommand:
                        // Ensure the next keyword is TABLE
                        try ensureNextElementMatches(keyword: .tableKey)
                        
                        // Create storage for the alter command and pull the next
                        // element as the table name
                        var alter = ADSQLAlterTableInstruction()
                        alter.name = ADSQLParseQueue.shared.pop()
                        
                        // Pull the next key and take action based on it
                        let key = try nextKey()
                        switch key {
                        case .renameKey:
                            // Ensure the next keyword is TO
                            try ensureNextElementMatches(keyword: .toKey)
                            
                            // Pull the next element as the new table name
                            alter.renameTo = ADSQLParseQueue.shared.pop()
                            
                            // Save new instruction
                            instructions.append(alter)
                        case .addKey:
                            // Ensure the next keyword is COLUMN
                            try ensureNextElementMatches(keyword: .columnKey)
                            
                            // Get new column definitions
                            let (columns, _) = try parseColumnDefinition()
                            if columns.count == 0 {
                                throw ADSQLParseError.malformedSQLCommand(message: "Expected column definition not found or invalid after ALTER TABLE instruction")
                            } else {
                                // Save new column definition.
                                alter.column = columns[0]
                            }
                            
                            // Save new instruction
                            instructions.append(alter)
                        default:
                            // Invalid keyword
                            throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(key)` found.")
                        }
                        
                        // Reset
                        state = .seekCommand
                        makeUnique = false
                        ifNotExists = false
                        makeTemporary = false
                    default:
                        // Invalid keyword
                        throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
                    }
                case .createKey:
                    switch(state) {
                    case .seekCommand:
                        state = .creating
                    default:
                        // Invalid keyword
                        throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
                    }
                case .uniqueKey:
                    switch(state) {
                    case .creating:
                        makeUnique = true
                    default:
                        // Invalid keyword
                        throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
                    }
                case .indexKey:
                    switch(state) {
                    case .creating:
                        state = .creatingIndex
                    default:
                        // Invalid keyword
                        throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
                    }
                case .tempKey, .temporaryKey:
                    switch(state) {
                    case .creating:
                        makeTemporary = true
                    default:
                        // Invalid keyword
                        throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
                    }
                case .tableKey:
                    switch(state) {
                    case .creating:
                        state = .creatingTable
                    default:
                        // Invalid keyword
                        throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
                    }
                case .triggerKey:
                    switch(state) {
                    case .creating:
                        state = .creatingTrigger
                    default:
                        // Invalid keyword
                        throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
                    }
                case .viewKey:
                    switch(state) {
                    case .creating:
                        state = .creatingView
                    default:
                        // Invalid keyword
                        throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
                    }
                case .ifKey:
                    switch(state) {
                    case .creatingIndex, .creatingTable, .creatingTrigger, .creatingView:
                        // The next two keys **must** be NOT and EXISTS.
                        try ensureNextElementMatches(keyword: ADSQLKeyword.notKey)
                        try ensureNextElementMatches(keyword: ADSQLKeyword.existsKey)
                        ifNotExists = true
                    default:
                        // Invalid keyword
                        throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
                    }
                case .selectKey:
                    switch(state){
                    case .seekCommand:
                        instructions.append(try parseSelectStatement())
                    default:
                        // Invalid keyword
                        throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
                    }
                case .insertKey:
                    switch(state){
                    case .seekCommand:
                        instructions.append(try parseInsertStatement())
                    default:
                        // Invalid keyword
                        throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
                    }
                case .updateKey:
                    switch(state){
                    case .seekCommand:
                        instructions.append(try parseUpdateStatement())
                    default:
                        // Invalid keyword
                        throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
                    }
                case .deleteKey:
                    switch(state){
                    case .seekCommand:
                        instructions.append(try parseDeleteStatement())
                    default:
                        // Invalid keyword
                        throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
                    }
                case .dropKey:
                    switch(state){
                    case .seekCommand:
                        instructions.append(try parseDropStatement())
                    default:
                        // Invalid keyword
                        throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
                    }
                case .beginKey:
                    switch(state){
                    case .seekCommand:
                        instructions.append(try parseTransactionStatement(type: .beginImmediate))
                    default:
                        // Invalid keyword
                        throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
                    }
                case .commitKey, .endKey:
                    switch(state){
                    case .seekCommand:
                        instructions.append(try parseTransactionStatement(type: .commit))
                    default:
                        // Invalid keyword
                        throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
                    }
                case .rollbackKey:
                    switch(state){
                    case .seekCommand:
                        instructions.append(try parseTransactionStatement(type: .rollback))
                    default:
                        // Invalid keyword
                        throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
                    }
                case .savePointKey:
                    switch(state){
                    case .seekCommand:
                        instructions.append(try parseTransactionStatement(type: .savepoint))
                    default:
                        // Invalid keyword
                        throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
                    }
                case .releaseKey:
                    switch(state){
                    case .seekCommand:
                        instructions.append(try parseTransactionStatement(type: .releaseSavepoint))
                    default:
                        // Invalid keyword
                        throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
                    }
                default:
                    // Invalid keyword
                    throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
                }
            } else {
                switch(state) {
                case .creatingIndex:
                    instructions.append(try parseCreateIndex(withName: element, makeUnique, ifNotExists))
                case .creatingTable:
                    instructions.append(try parseCreateTable(withName: element, makeTemporary, ifNotExists))
                case .creatingTrigger:
                    instructions.append(try parseCreateTrigger(withName: element, makeTemporary, ifNotExists))
                case .creatingView:
                    instructions.append(try parseCreateView(withName: element, makeTemporary, ifNotExists))
                default:
                    // Found unknown keyword
                    throw ADSQLParseError.unknownKeyword(message: "`\(element)` is not a recognized SQL keyword.")
                }
                
                // Reset
                state = .seekCommand
                makeUnique = false
                ifNotExists = false
                makeTemporary = false
            }
        }
        
        // Return results
        return instructions
    }
    
    /// Parses a sub SQL statement embedded inside of another statement.
    /// - Returns: A collection of sub SQL instructions.
    /// - Remark: Throws a `ADSQLParseError` on issue
    private static func parseSubStatements() throws -> [ADSQLInstruction] {
        var instructions: [ADSQLInstruction] = []
        
        // Interpret parse queue
        while ADSQLParseQueue.shared.count > 0 {
            let element = ADSQLParseQueue.shared.pop()
            
            // Get next keyword
            if let keyword = ADSQLKeyword.get(fromString: element) {
                // Take action based on the given keyword
                switch(keyword) {
                case .semicolon:
                    // Hit the command separator, ignore for now
                    break
                case .updateKey:
                    instructions.append(try parseUpdateStatement())
                case .insertKey:
                    instructions.append(try parseInsertStatement())
                case .deleteKey:
                    instructions.append(try parseDeleteStatement())
                case .selectKey:
                    instructions.append(try parseSelectStatement())
                default:
                    // Invalid keyword
                    throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
                }
            } else {
                // Found unknown keyword
                throw ADSQLParseError.unknownKeyword(message: "`\(element)` is not a recognized SQL keyword.")
            }
        }
        
        // Return results
        return instructions
    }
    
    /// Pops the next available keyword off of the parser queue and throws an error if it does not match the expected keyword.
    /// - Parameter keyword: The next SQL keyword expected to be in the command string.
    private static func ensureNextElementMatches(keyword: ADSQLKeyword) throws {
        let element = ADSQLParseQueue.shared.pop()
        if let nextKeyword = ADSQLKeyword.get(fromString: element) {
            if keyword != nextKeyword {
                throw ADSQLParseError.invalidKeyword(message: "Expected `\(keyword.rawValue)` but found `\(nextKeyword.rawValue)`")
            }
        } else {
            // Found unknown keyword
            throw ADSQLParseError.unknownKeyword(message: "`\(element)` is not a recognized SQL keyword.")
        }
    }
    
    /// Looks at the upcoming element, ensures it is a SQL keyword and returnes it if it is.
    /// - Returns: The next `ADSQLKeyword` in the parse queue.
    private static func upcomingKey() throws -> ADSQLKeyword {
        // Get next element
        let element = ADSQLParseQueue.shared.lookAhead()
        if let keyword = ADSQLKeyword.get(fromString: element) {
            return keyword
        } else {
            throw ADSQLParseError.malformedSQLCommand(message: "Expected a keyword but got `\(element)`.")
        }
    }
    
    /// Looks at the next element, ensures it is a SQL keyword and returnes it if it is.
    /// - Returns: The next `ADSQLKeyword` in the parse queue.
    private static func nextKey() throws -> ADSQLKeyword {
        // Get next element
        let element = ADSQLParseQueue.shared.pop()
        if let keyword = ADSQLKeyword.get(fromString: element) {
            return keyword
        } else {
            throw ADSQLParseError.malformedSQLCommand(message: "Expected a keyword but got `\(element)`.")
        }
    }
    
    // MARK: - Parse Create Instructions
    /**
     Parses a CREATE INDEX statement from a SQL instruction.
     
     - Parameters:
         - name: The name of the index to create.
         - makeUnique: If `true`, make the index unique.
         - ifNotExists: If `true`, create the index if it doesn't already exists.
    */
    private static func parseCreateIndex(withName name: String, _ makeUnique: Bool, _ ifNotExists: Bool) throws -> ADSQLCreateIndexInstruction {
        var instruction = ADSQLCreateIndexInstruction()
        
        // Get index name
        instruction.indexName = ADSQLParseQueue.shared.pop()
        
        // The next key must be ON
        try ensureNextElementMatches(keyword: .onKey)
        
        // Get table name
        instruction.tableName = ADSQLParseQueue.shared.pop()
        
        // Get column list
        instruction.columnList = try parseColumnNameList()
        
        // The next key must be WHERE
        try ensureNextElementMatches(keyword: .whereKey)
        
        // Get where expression
        instruction.whereExpression = try parseWhereExpression()
        
        return instruction
    }
    
    /**
     Parses a CREATE TABLE statement from a SQL instruction.
     
     - Parameters:
         - name: The name of the table to create.
         - makeTemporary: If `true`, make the table temporary.
         - ifNotExists: If `true`, create the table if it doesn't already exists.
     */
    private static func parseCreateTable(withName name: String, _ makeTemporary: Bool, _ ifNotExists: Bool) throws -> ADSQLCreateTableInstruction {
        var instruction = ADSQLCreateTableInstruction(tableName: name, makeTemporary, ifNotExists)
        
        let element = ADSQLParseQueue.shared.pop()
        
        // Get next keyword
        if let keyword = ADSQLKeyword.get(fromString: element) {
            switch(keyword) {
            case .asKey:
                instruction.selectStatement = try parseSelectStatement()
            case .openParenthesis:
                let results = try parseColumnDefinition()
                instruction.columns = results.columns
                instruction.constraints = results.tableConstraints
                
                let keyword = try upcomingKey()
                if keyword == .withoutKey {
                    // Consume key
                    ADSQLParseQueue.shared.pop()
                    try ensureNextElementMatches(keyword: .rowIDKey)
                    instruction.withoutRowID = true
                }
            default:
                // Invalid keyword
                throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
            }
        } else {
            // Found unknown keyword
            throw ADSQLParseError.unknownKeyword(message: "`\(element)` is not a recognized SQL keyword.")
        }
        
        return instruction
    }
    
    /**
     Parses a CREATE TRIGGER statement from a SQL instruction.
     
     - Parameters:
         - name: The name of the trigger to create.
         - makeTemporary: If `true`, make the trigger temporary.
         - ifNotExists: If `true`, create the trigger if it doesn't already exists.
     */
    private static func parseCreateTrigger(withName name: String, _ makeTemporary: Bool, _ ifNotExists: Bool) throws -> ADSQLCreateTriggerInstruction {
        var instruction = ADSQLCreateTriggerInstruction()
        
        // Get trigger name
        instruction.triggerName = ADSQLParseQueue.shared.pop()
        
        // Get the next key
        var key = try nextKey()
        switch key {
        case .beforeKey:
            instruction.triggerWhen = .before
        case .afterKey:
            instruction.triggerWhen = .after
        case .insteadKey:
            // The next key must be OF
            try ensureNextElementMatches(keyword: .ofKey)
            instruction.triggerWhen = .insteadOf
        default:
            // Invalid keyword
            throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(key)` found.")
        }
        
        // Get next keyword
        key = try nextKey()
        switch key {
        case .deleteKey:
            instruction.triggerType = .delete
        case .insertKey:
            instruction.triggerType = .insert
        case .updateKey:
            // The next key must be OF
            try ensureNextElementMatches(keyword: .ofKey)
            instruction.columnList = try parseColumnNameList(initialState: .inColumnList)
        default:
            // Invalid keyword
            throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(key)` found.")
        }
        
        // The next key must be ON
        try ensureNextElementMatches(keyword: .onKey)
        
        // Get table name
        instruction.tableName = ADSQLParseQueue.shared.pop()
        
        // Get the next key
        key = try nextKey()
        switch key {
        case .forKey:
            // The next two keywords must be EACH and ROW
            try ensureNextElementMatches(keyword: .eachKey)
            try ensureNextElementMatches(keyword: .rowKey)
            instruction.forEachRow = true
        case .whenKey:
            instruction.whenExpression = try parseExpression()
        default:
            // Invalid keyword
            throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(key)` found.")
        }
        
        // The next keyword must be BEGIN
        try ensureNextElementMatches(keyword: .beginKey)
        
        // Get instruction list
        instruction.instructions = try parseSubStatements()
        
        // The next keyword must be END
        try ensureNextElementMatches(keyword: .endKey)
        
        return instruction
    }
    
    /**
     Parses a CREATE VIEW statement from a SQL instruction.
     
     - Parameters:
         - name: The name of the view to create.
         - makeTemporary: If `true`, make the view temporary.
         - ifNotExists: If `true`, create the view if it doesn't already exists.
     */
    private static func parseCreateView(withName name: String, _ makeTemporary: Bool, _ ifNotExists: Bool) throws -> ADSQLCreateViewInstruction {
        var instruction = ADSQLCreateViewInstruction()
        
        // Get the view name
        instruction.viewName = ADSQLParseQueue.shared.pop()
        
        // Has column name list?
        if ADSQLParseQueue.shared.lookAhead() == "(" {
            instruction.columnList = try parseColumnNameList()
        }
        
        // The next key must be AS
        try ensureNextElementMatches(keyword: .asKey)
        
        // Add select statement
        instruction.selectStatement = try parseSelectStatement()
        
        return instruction
    }
    
    // MARK: - Select Instructions
    /// Parses a SELECT clause from the SQL instruction.
    /// - Returns: A `ADSQLSelectInstruction` representing the select clause.
    private static func parseSelectStatement() throws -> ADSQLSelectInstruction {
        var instruction = ADSQLSelectInstruction()
        
        // All or distinct?
        var element = ADSQLParseQueue.shared.lookAhead().uppercased()
        if element == "DISTINCT" {
            // Consume key
            ADSQLParseQueue.shared.pop()
            instruction.distinct = true
        } else if element == "ALL" {
            // Consume key
            ADSQLParseQueue.shared.pop()
            instruction.distinct = false
        }
        
        // Get the column list
        instruction.columns = try parseResultColumnList()
        
        // The next key must be from
        try ensureNextElementMatches(keyword: .fromKey)
        
        // Get the source
        instruction.fromSouce = try parserJoinClause()
        
        // Look ahead to next item
        element = ADSQLParseQueue.shared.lookAhead().uppercased()
        
        // Where clause?
        if element == "WHERE" {
            // Consume key
            ADSQLParseQueue.shared.pop()
            instruction.whereExpression = try parseWhereExpression()
            element = ADSQLParseQueue.shared.lookAhead().uppercased()
        }
        
        // Group by clause?
        if element == "GROUP" {
            // Consume key
            ADSQLParseQueue.shared.pop()
            try ensureNextElementMatches(keyword: .byKey)
            instruction.groupByColumns = try parseGroupBy()
            
            // Has having clause?
            element = ADSQLParseQueue.shared.lookAhead().uppercased()
            if element == "HAVING" {
                // Consume key
                ADSQLParseQueue.shared.pop()
                instruction.havingExpression = try parseWhereExpression()
                element = ADSQLParseQueue.shared.lookAhead().uppercased()
            }
        }
        
        // Order by clause?
        if element == "ORDER" {
            // Consume key
            ADSQLParseQueue.shared.pop()
            try ensureNextElementMatches(keyword: .byKey)
            instruction.orderBy = try parseOrderBy()
            element = ADSQLParseQueue.shared.lookAhead().uppercased()
        }
        
        // Limit clause?
        if element == "LIMIT" {
            // Consume key
            ADSQLParseQueue.shared.pop()
            let val1 = ADSQLParseQueue.shared.pop()
            
            element = ADSQLParseQueue.shared.lookAhead().uppercased()
            if element == "OFFSET" {
                // Consume key
                ADSQLParseQueue.shared.pop()
                let val2 = ADSQLParseQueue.shared.pop()
                
                if let value = Int(val1) {
                    instruction.limit = value
                } else {
                    throw ADSQLParseError.expectedIntValue(message: "Expected an integer after the LIMIT clause but got `\(val1)` instead.")
                }
                
                if let value = Int(val2) {
                    instruction.offset = value
                } else {
                    throw ADSQLParseError.expectedIntValue(message: "Expected an integer after the OFFSET clause but got `\(val1)` instead.")
                }
            } else if element == "," {
                // Consume key
                ADSQLParseQueue.shared.pop()
                let val2 = ADSQLParseQueue.shared.pop()
                
                if let value = Int(val2) {
                    instruction.limit = value
                } else {
                    throw ADSQLParseError.expectedIntValue(message: "Expected an integer after the LIMIT n,x clause but got `\(val1)` instead.")
                }
                
                if let value = Int(val1) {
                    instruction.offset = value
                } else {
                    throw ADSQLParseError.expectedIntValue(message: "Expected an integer after the LIMIT n,x clause but got `\(val1)` instead.")
                }
            } else {
                if let value = Int(val1) {
                    instruction.limit = value
                } else {
                    throw ADSQLParseError.expectedIntValue(message: "Expected an integer after the LIMIT clause but got `\(val1)` instead.")
                }
            }
        }
        
        // Return result
        return instruction
    }
    
    /// Parses a JOIN clause from a SELECT clause in a SQL instruction.
    /// - Returns: A `ADSQLJoinClause` representing the JOIN clause.
    private static func parserJoinClause() throws -> ADSQLJoinClause {
        let joinClause = ADSQLJoinClause()
        var joinRequired = false
        
        // Get table name
        joinClause.parentTable = ADSQLParseQueue.shared.pop()
        
        // Look ahead to next element
        var element = ADSQLParseQueue.shared.lookAhead().uppercased()
        
        // Defining an alias?
        if element == "AS" {
            ADSQLParseQueue.shared.pop()
            joinClause.parentTableAlias = ADSQLParseQueue.shared.pop()
            element = ADSQLParseQueue.shared.lookAhead().uppercased()
        }
        
        // Look for possible type
        switch element {
        case "NATURAL":
            ADSQLParseQueue.shared.pop()
            joinClause.type = .natural
            element = ADSQLParseQueue.shared.lookAhead().uppercased()
            joinRequired = true
        case "LEFT":
            ADSQLParseQueue.shared.pop()
            try ensureNextElementMatches(keyword: .outerKey)
            joinClause.type = .leftOuter
            element = ADSQLParseQueue.shared.lookAhead().uppercased()
            joinRequired = true
        case "INNER":
            ADSQLParseQueue.shared.pop()
            joinClause.type = .inner
            element = ADSQLParseQueue.shared.lookAhead().uppercased()
            joinRequired = true
        case "CROSS":
            ADSQLParseQueue.shared.pop()
            joinClause.type = .cross
            element = ADSQLParseQueue.shared.lookAhead().uppercased()
            joinRequired = true
        default:
            break
        }
        
        // Is this a join or single table definition?
        if element == "JOIN" {
            ADSQLParseQueue.shared.pop()
            if joinClause.type == .none {
                // Default to a inner join
                joinClause.type = .inner
            }
            joinClause.childTable = ADSQLParseQueue.shared.pop()
            element = ADSQLParseQueue.shared.lookAhead().uppercased()
            
            // Defining an alias?
            if element == "AS" {
                ADSQLParseQueue.shared.pop()
                joinClause.childTableAlias = ADSQLParseQueue.shared.pop()
                element = ADSQLParseQueue.shared.lookAhead().uppercased()
            }
            
            // Supplying a list of conditions?
            if element == "ON" {
                ADSQLParseQueue.shared.pop()
                joinClause.onExpression = try parseWhereExpression()
            } else if element == "USING" {
                ADSQLParseQueue.shared.pop()
                joinClause.columnList = try parseColumnNameList()
            }
            
            // Check to see if the child is part of a join as well
            joinClause.childJoin = try continueParsingJoin(with: joinClause.childTable)
        } else if joinRequired {
            throw ADSQLParseError.malformedSQLCommand(message: "Expected JOIN but received `\(element)` parsing SELECT statement.")
        }
        
        return joinClause
    }
    
    /**
     Checks to see if the current join is further joined to another table and returns the resulting sub join if it exists.
     
     - Parameter parent: The child table that is the possible parent of a sub join.
     - Returns: A `ADJoinClause` representing the sub join if one exists or returns `nil`.
    */
    private static func continueParsingJoin(with parent: String) throws -> ADSQLJoinClause? {
        let joinClause = ADSQLJoinClause()
        var joinRequired = false
        
        // Setup potential join
        joinClause.parentTable = parent
        
        // Look ahead to next element
        var element = ADSQLParseQueue.shared.lookAhead().uppercased()
        
        // Look for possible type
        switch element {
        case "NATURAL":
            ADSQLParseQueue.shared.pop()
            joinClause.type = .natural
            element = ADSQLParseQueue.shared.lookAhead().uppercased()
            joinRequired = true
        case "LEFT":
            ADSQLParseQueue.shared.pop()
            try ensureNextElementMatches(keyword: .outerKey)
            joinClause.type = .leftOuter
            element = ADSQLParseQueue.shared.lookAhead().uppercased()
            joinRequired = true
        case "INNER":
            ADSQLParseQueue.shared.pop()
            joinClause.type = .inner
            element = ADSQLParseQueue.shared.lookAhead().uppercased()
            joinRequired = true
        case "CROSS":
            ADSQLParseQueue.shared.pop()
            joinClause.type = .cross
            element = ADSQLParseQueue.shared.lookAhead().uppercased()
            joinRequired = true
        default:
            break
        }
        
        // Is this a join or single table definition?
        if element == "JOIN" {
            ADSQLParseQueue.shared.pop()
            if joinClause.type == .none {
                // Default to a inner join
                joinClause.type = .inner
            }
            joinClause.childTable = ADSQLParseQueue.shared.pop()
            element = ADSQLParseQueue.shared.lookAhead().uppercased()
            
            // Defining an alias?
            if element == "AS" {
                ADSQLParseQueue.shared.pop()
                joinClause.childTableAlias = ADSQLParseQueue.shared.pop()
                element = ADSQLParseQueue.shared.lookAhead().uppercased()
            }
            
            // Supplying a list of conditions?
            if element == "ON" {
                ADSQLParseQueue.shared.pop()
                joinClause.onExpression = try parseWhereExpression()
            } else if element == "USING" {
                ADSQLParseQueue.shared.pop()
                joinClause.columnList = try parseColumnNameList()
            }
            
            // Check to see if the child is part of a join as well
            joinClause.childJoin = try continueParsingJoin(with: joinClause.childTable)
            
            // Return completed sub join
            return joinClause
        } else if joinRequired {
            throw ADSQLParseError.malformedSQLCommand(message: "Expected JOIN but received `\(element)` parsing SELECT statement.")
        }
        
        // Join is not continued
        return nil
    }
    
    /// Parses a GROUP BY clause from a SELECT clause in a SQL instruction.
    /// - Returns: An array of `ADSQLExpressions` representing the GROUP BY clause.
    private static func parseGroupBy() throws -> [String] {
        var columns: [String] = []
        var done = false
        
        while !done {
            columns.append(ADSQLParseQueue.shared.pop())
            
            let element = ADSQLParseQueue.shared.lookAhead().uppercased()
            switch element {
            case ",":
                // Consume key
                ADSQLParseQueue.shared.pop()
            case "", "HAVING", "ORDER", "LIMIT":
                done = true
            default:
                throw ADSQLParseError.invalidKeyword(message: "Expected `,`, `HAVING`, `ORDER BY` or `LIMIT` but received `\(element)` while parsing GROUP BY statement.")
            }
        }
        
        return columns
    }
    
    /// Parses a ORDER BY clause from a SELECT clause in a SQL instruction.
    /// - Returns: An array of `ADSQLOrderByClause` representing the ORDER BY clause.
    private static func parseOrderBy() throws -> [ADSQLOrderByClause] {
        var clauses: [ADSQLOrderByClause] = []
        var clause = ADSQLOrderByClause(on: "")
        var done = false
        var state = parseState.seekOrderBy
        
        while !done {
            if state == .seekOrderBy {
                clause = ADSQLOrderByClause(on: ADSQLParseQueue.shared.pop())
                state = .inOrderBy
            }
            
            let element = ADSQLParseQueue.shared.lookAhead().uppercased()
            switch element {
            case "ASC":
                // Consume key
                ADSQLParseQueue.shared.pop()
                clause.order = .ascending
            case "DESC":
                // Consume key
                ADSQLParseQueue.shared.pop()
                clause.order = .descending
            case "COLLATE":
                // Consume key
                ADSQLParseQueue.shared.pop()
                clause.collationName = ADSQLParseQueue.shared.pop()
            case ",":
                // Consume key
                ADSQLParseQueue.shared.pop()
                clauses.append(clause)
                state = .seekOrderBy
            case "","LIMIT":
                clauses.append(clause)
                done = true
            default:
                throw ADSQLParseError.invalidKeyword(message: "Expected `,`, `ASC`, `DESC`, `COLLATE` or `LIMIT` but received `\(element)` while parsing ORDER BY statement.")
            }
        }
        
        return clauses
    }
    
    // MARK: - Insert Instructions
    /// Parses an INSERT clause in a SQL Instruction.
    /// - Returns: A `ADSQLInsertInstruction` representing the INSERT clause.
    private static func parseInsertStatement() throws -> ADSQLInsertInstruction {
        var instruction = ADSQLInsertInstruction()
        
        // Get first key
        var key = try nextKey()
        
        // Or clause?
        if key == .orKey {
            key = try nextKey()
            switch key {
            case .replaceKey:
                instruction.action = .insertOrReplace
            case .rollbackKey:
                instruction.action = .insertOrRollback
            case .abortKey:
                instruction.action = .insertOrAbort
            case .failKey:
                instruction.action = .insertOrFail
            case .ignoreKey:
                instruction.action = .insertOrIgnore
            default:
                throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(key)` found parsing INSERT statement.")
            }
            
            // The next key must be INTO
            try ensureNextElementMatches(keyword: .intoKey)
        } else if key != .intoKey {
            throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(key)` found parsing INSERT statement.")
        }
        
        // Get table name
        instruction.tableName = ADSQLParseQueue.shared.pop()
        
        // Get next key
        key = try nextKey()
        
        // List of column names?
        if key == .openParenthesis {
            instruction.columnNames = try parseColumnNameList(initialState: .inColumnList)
            key = try nextKey()
        }
        
        // Take action based on key
        switch key {
        case .valuesKey:
            instruction.values = try parseValues()
        case .selectKey:
            instruction.selectStatement = try parseSelectStatement()
        case .defaultKey:
            try ensureNextElementMatches(keyword: .valuesKey)
            instruction.defaultValues = true
        default:
            throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(key)` found parsing INSERT statement.")
        }
        
        return instruction
    }
    
    /// Parses a list of values from an INSERT clause in a SQL instruction.
    /// - Returns: An array of `ADSQLExpression` representing the values.
    private static func parseValues() throws -> [ADSQLExpression] {
        var expressions: [ADSQLExpression] = []
        var done = false
        
        // The next key must be an open parenthesis
        try ensureNextElementMatches(keyword: .openParenthesis)
        
        while !done {
            expressions.append(try parseExpression())
            
            let key = try nextKey()
            switch key {
            case .comma:
                break
            case .closedParenthesis:
                done = true
            default:
                throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(key)` found parsing INSERT statement.")
            }
        }
        
        return expressions
    }
    
    // MARK: - Update Instructions
    /// Parses an UPDATE clause from a SQL instruction.
    /// - Returns: A `ADSQLUpdateInstruction` representing the UPDATE clause.
    private static func parseUpdateStatement() throws -> ADSQLUpdateInstruction {
        var instruction = ADSQLUpdateInstruction()
        var done = false
        
        // Or clause?
        var element = ADSQLParseQueue.shared.lookAhead().uppercased()
        if element == "OR" {
            // Consume key
            ADSQLParseQueue.shared.pop()
            let key = try nextKey()
            switch key {
            case .rollbackKey:
                instruction.action = .updateOrRollback
            case .abortKey:
                instruction.action = .updateOrAbort
            case .replaceKey:
                instruction.action = .updateOrReplace
            case .failKey:
                instruction.action = .updateOrFail
            case .ignoreKey:
                instruction.action = .updateOrIgnore
            default:
                throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(key)` found parsing UPDATE statement.")
            }
        }
        
        // Get table name
        instruction.tableName = ADSQLParseQueue.shared.pop()
        
        // The next key must be SET
        try ensureNextElementMatches(keyword: .setKey)
        
        // Get set instructions
        while !done {
            var set = ADSQLSetClause()
            set.columnName = ADSQLParseQueue.shared.pop()
            try ensureNextElementMatches(keyword: .equal)
            set.expression = try parseExpression()
            instruction.setClauses.append(set)
            
            let element = ADSQLParseQueue.shared.lookAhead().uppercased()
            if element == "," {
                // Consume key
                ADSQLParseQueue.shared.pop()
            } else {
                // Finished parsing
                done = true
            }
        }
        
        // Where clause?
        element = ADSQLParseQueue.shared.lookAhead().uppercased()
        if element == "WHERE" {
            // Consume key
            ADSQLParseQueue.shared.pop()
            instruction.whereExpression = try parseWhereExpression()
        }
        
        return instruction
    }
    
    // MARK: - Delete Instructions
    /// Parses a DELETE clause from a SQL instruction.
    /// - Returns: A `ADSQLDeleteInstruction` representing the DELETE clause.
    private static func parseDeleteStatement() throws -> ADSQLDeleteInstruction {
        var instruction = ADSQLDeleteInstruction()
        
        // The next key must be from
        try ensureNextElementMatches(keyword: .fromKey)
        
        // Get table name
        instruction.tableName = ADSQLParseQueue.shared.pop()
        
        // Where clause?
        let element = ADSQLParseQueue.shared.lookAhead().uppercased()
        if element == "WHERE" {
            // Consume key
            ADSQLParseQueue.shared.pop()
            instruction.whereExpression = try parseWhereExpression()
        }
        
        return instruction
    }
    
    // MARK: - Drop Instructions
    /// Parses a DROP clause from a SQL instruction.
    /// - Returns: A `ADSQLDropInstruction` representing the DROP clause.
    private static func parseDropStatement() throws -> ADSQLDropInstruction {
        var instruction = ADSQLDropInstruction()
        
        // Get next key
        let key = try nextKey()
        
        // Set action
        switch key {
        case .indexKey:
            instruction.action = .index
        case .tableKey:
            instruction.action = .table
        case .triggerKey:
            instruction.action = .trigger
        case .viewKey:
            instruction.action = .view
        default:
            throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(key)` found parsing DROP statement.")
        }
        
        // If clause?
        let element = ADSQLParseQueue.shared.lookAhead().uppercased()
        if element == "IF" {
            // Consume key
            ADSQLParseQueue.shared.pop()
            try ensureNextElementMatches(keyword: .existsKey)
            instruction.ifExists = true
        }
        
        // Get item name
        instruction.itemName = ADSQLParseQueue.shared.pop()
        
        return instruction
    }
    
    // MARK: - Transaction Instructions
    /// Parses a transaction clause from a SQL instruction.
    /// - Returns: A `ADSQLTransactionInstruction` representing the transaction clause.
    private static func parseTransactionStatement(type: ADSQLTransactionInstruction.Action) throws -> ADSQLTransactionInstruction {
        var instruction = ADSQLTransactionInstruction(forAction: type)
        
        // Look at next element
        var element = ADSQLParseQueue.shared.lookAhead().uppercased()
        switch element {
        case "DEFERRED":
            // Consume key
            ADSQLParseQueue.shared.pop()
            instruction.action = .beginDeferred
            element = ADSQLParseQueue.shared.lookAhead().uppercased()
        case "IMMEDIATE":
            // Consume key
            ADSQLParseQueue.shared.pop()
            instruction.action = .beginImmediate
            element = ADSQLParseQueue.shared.lookAhead().uppercased()
        case "EXCLUSIVE":
            // Consume key
            ADSQLParseQueue.shared.pop()
            instruction.action = .beginExclusive
            element = ADSQLParseQueue.shared.lookAhead().uppercased()
        default:
            break
        }
        
        // Transaction keyword?
        if element == "TRANSACTION" {
            // Consume key
            ADSQLParseQueue.shared.pop()
        }
        
        switch instruction.action {
        case .rollback:
            element = ADSQLParseQueue.shared.lookAhead().uppercased()
            if element == "TO" {
                // Consume key
                ADSQLParseQueue.shared.pop()
                try ensureNextElementMatches(keyword: .savePointKey)
                instruction.savepointName = ADSQLParseQueue.shared.pop()
            }
        case .savepoint:
            instruction.savepointName = ADSQLParseQueue.shared.pop()
        case .releaseSavepoint:
            element = ADSQLParseQueue.shared.lookAhead().uppercased()
            if element == "SAVEPOINT" {
                // Consume key
                ADSQLParseQueue.shared.pop()
            }
            instruction.savepointName = ADSQLParseQueue.shared.pop()
        default:
            break
        }
        
        return instruction
    }
    
    // MARK: - Column Parsers
    /// Parses a column definition from a CREATE TABLE clause in a SQL instruction.
    /// - Returns: A tuple containing the column definitions as a `ADSQLColumnDefinition` array and any optional table constraints as a `ADSQLTableConstraint` array.
    private static func parseColumnDefinition() throws -> (columns: [ADSQLColumnDefinition], tableConstraints: [ADSQLTableConstraint]) {
        var columns: [ADSQLColumnDefinition] = []
        var tableConstraints: [ADSQLTableConstraint] = []
        var state = parseState.seekColumnDef
        var column = ADSQLColumnDefinition()
        var constraint = ADSQLColumnConstraint()
        var tableConstraint = ADSQLTableConstraint()
        var hasConflictHandling = false
        var forTable = false
        
        // Interpret parse queue
        while ADSQLParseQueue.shared.count > 0 {
            let element = ADSQLParseQueue.shared.pop()
            
            // Get next keyword
            if let keyword = ADSQLKeyword.get(fromString: element) {
                switch(keyword) {
                case .comma:
                    switch(state){
                    case .seekConstraint:
                        // Save definition
                        columns.append(column)
                        state = .seekColumnDef
                    case .inConstraint:
                        // Save definition
                        column.constraints.append(constraint)
                        columns.append(column)
                        state = .seekColumnDef
                    case .inTableConstraint:
                        // Save definition
                        tableConstraints.append(tableConstraint)
                        state = .seekTableConstraint
                    default:
                        // Invalid type definition
                        throw ADSQLParseError.malformedSQLCommand(message: "Found `,` but was expecting a column name or constraint.")
                    }
                case .closedParenthesis, .semicolon:
                    switch(state){
                    case .seekConstraint:
                        // Save definition
                        columns.append(column)
                        return (columns, tableConstraints)
                    case .inConstraint:
                        // Save definition
                        column.constraints.append(constraint)
                        columns.append(column)
                        return (columns, tableConstraints)
                    case .inTableConstraint, .seekTableConstraint:
                        // Save definition
                        tableConstraints.append(tableConstraint)
                        return (columns, tableConstraints)
                    default:
                        // Invalid type definition
                        throw ADSQLParseError.malformedSQLCommand(message: "Found `)` but was expecting a column name or constraint.")
                    }
                case .primaryKey:
                    switch(state) {
                    case .seekConstraint:
                        // The next word must be KEY
                        try ensureNextElementMatches(keyword: ADSQLKeyword.keyKey)
                        constraint = ADSQLColumnConstraint(ofType: .primaryKeyAsc)
                        state = .inConstraint
                        hasConflictHandling = true
                        forTable = false
                    case .inConstraint:
                        column.constraints.append(constraint)
                        // The next word must be KEY
                        try ensureNextElementMatches(keyword: ADSQLKeyword.keyKey)
                        constraint = ADSQLColumnConstraint(ofType: .primaryKeyAsc)
                        state = .inConstraint
                        hasConflictHandling = true
                        forTable = false
                    case .seekColumnDef, .seekTableConstraint:
                        // The next word must be KEY
                        try ensureNextElementMatches(keyword: ADSQLKeyword.keyKey)
                        tableConstraint = ADSQLTableConstraint(typeOf: .primaryKey)
                        state = .inTableConstraint
                        hasConflictHandling = true
                        forTable = true
                        tableConstraint.columnList = try parseColumnNameList()
                    default:
                        // Invalid keyword
                        throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
                    }
                case .ascKey:
                    if state == .inConstraint && constraint.type == .primaryKeyAsc {
                        constraint.type = .primaryKeyAsc
                    } else {
                        // Invalid keyword
                        throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
                    }
                case .descKey:
                    if state == .inConstraint && constraint.type == .primaryKeyAsc {
                        constraint.type = .primaryKeyDesc
                    } else {
                        // Invalid keyword
                        throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
                    }
                case .autoIncrementKey:
                    if state == .inConstraint && (constraint.type == .primaryKeyAsc || constraint.type == .primaryKeyDesc) {
                        constraint.autoIncrement = true
                    } else {
                        // Invalid keyword
                        throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
                    }
                case .onKey:
                    if hasConflictHandling && state == .inConstraint {
                        // The next word must be CONFLICT
                        try ensureNextElementMatches(keyword: ADSQLKeyword.conflictKey)
                        state = .inConflictClause
                    } else {
                        // Invalid keyword
                        throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
                    }
                case .rollbackKey:
                    if state == .inConflictClause {
                        if forTable {
                            tableConstraint.conflictHandling = .rollback
                        } else {
                            constraint.conflictHandling = .rollback
                        }
                        state = .inConstraint
                    } else {
                        // Invalid keyword
                        throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
                    }
                case .abortKey:
                    if state == .inConflictClause {
                        if forTable {
                            tableConstraint.conflictHandling = .abort
                        } else {
                            constraint.conflictHandling = .abort
                        }
                        state = .inConstraint
                    } else {
                        // Invalid keyword
                        throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
                    }
                case .failKey:
                    if state == .inConflictClause {
                        if forTable {
                            tableConstraint.conflictHandling = .fail
                        } else {
                            constraint.conflictHandling = .fail
                        }
                        state = .inConstraint
                    } else {
                        // Invalid keyword
                        throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
                    }
                case .ignoreKey:
                    if state == .inConflictClause {
                        if forTable {
                            tableConstraint.conflictHandling = .ignore
                        } else {
                            constraint.conflictHandling = .ignore
                        }
                        state = .inConstraint
                    } else {
                        // Invalid keyword
                        throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
                    }
                case .replaceKey:
                    if state == .inConflictClause {
                        if forTable {
                            tableConstraint.conflictHandling = .replace
                        } else {
                            constraint.conflictHandling = .replace
                        }
                        state = .inConstraint
                    } else {
                        // Invalid keyword
                        throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
                    }
                case .notKey:
                    switch(state) {
                    case .seekConstraint:
                        // The next word must be NULL
                        try ensureNextElementMatches(keyword: ADSQLKeyword.nullKey)
                        constraint = ADSQLColumnConstraint(ofType: .notNull)
                        state = .inConstraint
                        hasConflictHandling = true
                    case .inConstraint:
                        column.constraints.append(constraint)
                        // The next word must be NULL
                        try ensureNextElementMatches(keyword: ADSQLKeyword.nullKey)
                        constraint = ADSQLColumnConstraint(ofType: .notNull)
                        state = .inConstraint
                        hasConflictHandling = true
                    default:
                        // Invalid keyword
                        throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
                    }
                case .uniqueKey:
                    switch(state) {
                    case .seekConstraint:
                        constraint = ADSQLColumnConstraint(ofType: .unique)
                        state = .inConstraint
                        hasConflictHandling = true
                        forTable = false
                    case .inConstraint:
                        column.constraints.append(constraint)
                        constraint = ADSQLColumnConstraint(ofType: .unique)
                        state = .inConstraint
                        hasConflictHandling = true
                        forTable = false
                    case .seekColumnDef, .seekTableConstraint:
                        tableConstraint = ADSQLTableConstraint(typeOf: .unique)
                        state = .inTableConstraint
                        hasConflictHandling = true
                        forTable = true
                        tableConstraint.columnList = try parseColumnNameList()
                    default:
                        // Invalid keyword
                        throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
                    }
                case .checkKey:
                    switch(state) {
                    case .seekConstraint:
                        constraint = ADSQLColumnConstraint(ofType: .check, withExpression: ADSQLFunctionExpression(functionType: .check, parameters: try parseFunctionParameters()))
                        state = .inConstraint
                        hasConflictHandling = false
                    case .inConstraint:
                        column.constraints.append(constraint)
                        constraint = ADSQLColumnConstraint(ofType: .check, withExpression: ADSQLFunctionExpression(functionType: .check, parameters: try parseFunctionParameters()))
                        state = .inConstraint
                        hasConflictHandling = false
                    case .seekColumnDef, .seekTableConstraint:
                        tableConstraint = ADSQLTableConstraint(typeOf: .check, withExpression: ADSQLFunctionExpression(functionType: .check, parameters: try parseFunctionParameters()))
                        state = .seekTableConstraint
                        hasConflictHandling = false
                    default:
                        // Invalid keyword
                        throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
                    }
                case .defaultKey:
                    let nextElement = ADSQLParseQueue.shared.lookAhead()
                    switch(state) {
                    case .seekConstraint:
                        if nextElement == "(" {
                            constraint = ADSQLColumnConstraint(ofType: .defaultValue, withExpression: try parseExpression())
                        } else {
                            constraint = ADSQLColumnConstraint(ofType: .defaultValue, withExpression: ADSQLLiteralExpression(value: ADSQLParseQueue.shared.pop()))
                        }
                        state = .inConstraint
                        hasConflictHandling = false
                    case .inConstraint:
                        column.constraints.append(constraint)
                        if nextElement == "(" {
                            constraint = ADSQLColumnConstraint(ofType: .defaultValue, withExpression: try parseExpression())
                        } else {
                            constraint = ADSQLColumnConstraint(ofType: .defaultValue, withExpression: ADSQLLiteralExpression(value: ADSQLParseQueue.shared.pop()))
                        }
                        state = .inConstraint
                        hasConflictHandling = false
                    default:
                        // Invalid keyword
                        throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
                    }
                case .collateKey:
                    switch(state) {
                    case .seekConstraint:
                        constraint = ADSQLColumnConstraint(ofType: .collate, withExpression: ADSQLLiteralExpression(value: ADSQLParseQueue.shared.pop()))
                        state = .inConstraint
                        hasConflictHandling = false
                    case .inConstraint:
                        column.constraints.append(constraint)
                        constraint = ADSQLColumnConstraint(ofType: .collate, withExpression: ADSQLLiteralExpression(value: ADSQLParseQueue.shared.pop()))
                        state = .inConstraint
                        hasConflictHandling = false
                    default:
                        // Invalid keyword
                        throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
                    }
                case .referencesKey:
                    switch(state) {
                    case .seekConstraint:
                        constraint = ADSQLColumnConstraint(ofType: .foreignKey, withExpression: try parseForeignKeyExpression())
                        state = .inConstraint
                        hasConflictHandling = false
                    case .inConstraint:
                        column.constraints.append(constraint)
                        constraint = ADSQLColumnConstraint(ofType: .foreignKey, withExpression: try parseForeignKeyExpression())
                        state = .inConstraint
                        hasConflictHandling = false
                    default:
                        // Invalid keyword
                        throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
                    }
                case .foreignKey:
                    switch(state) {
                    case .seekColumnDef, .seekTableConstraint:
                        // The next word must be KEY
                        try ensureNextElementMatches(keyword: ADSQLKeyword.keyKey)
                        tableConstraint = ADSQLTableConstraint(typeOf: .foreignKey, withExpression: try parseForeignKeyExpression())
                        state = .seekTableConstraint
                        hasConflictHandling = false
                    default:
                        // Invalid keyword
                        throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
                    }
                default:
                    // Invalid keyword
                    throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
                }
            } else if let type = ADSQLColumnType.get(fromString: element) {
                if state == .seekType {
                    column.type = type
                    state = .seekConstraint
                } else {
                    // Invalid type definition
                    throw ADSQLParseError.malformedSQLCommand(message: "Found type `\(type)` but was expecting a column name or constraint.")
                }
            } else {
                switch(state) {
                case .seekColumnDef:
                    column = ADSQLColumnDefinition(columnName: element)
                    state = .seekType
                default:
                    // Found unknown keyword
                    throw ADSQLParseError.unknownKeyword(message: "`\(element)` is not a recognized SQL keyword.")
                }
            }
        }
        
        return (columns, tableConstraints)
    }
    
    /// Parses a list of simple column names from a SQL instuction.
    /// - Returns: An array of column names.
    private static func parseColumnNameList(initialState: parseState = .seekColumnList) throws -> [String] {
        var names: [String] = []
        var state = initialState
        
        // Parse the list of column names
        while ADSQLParseQueue.shared.count > 0 {
            // Get the next element
            let element = ADSQLParseQueue.shared.pop()
            
            // Is this a keyword
            if let keyword = ADSQLKeyword.get(fromString: element) {
                switch(keyword) {
                case .openParenthesis:
                    if state == .seekColumnList {
                        state = .inColumnList
                    } else {
                        throw ADSQLParseError.malformedSQLCommand(message: "Found unexpected `(` while parsing column name list.")
                    }
                case .comma:
                    // Just ignore for now
                    break
                case .closedParenthesis:
                    return names
                default:
                    throw ADSQLParseError.malformedSQLCommand(message: "Found keyword `\(keyword)` but was expecting a column name.")
                }
            } else {
                // Accumulate name
                if state == .inColumnList {
                    names.append(element)
                } else {
                    throw ADSQLParseError.malformedSQLCommand(message: "Found `\(element)` but expected `(` to start list of column names.")
                }
            }
            
            // Looking for on keyword?
            if initialState == .inColumnList {
                if ADSQLParseQueue.shared.lookAhead().uppercased() == "ON" {
                    return names
                }
            }
        }
        
        // Missing last )
        throw ADSQLParseError.mismatchedParenthesis(message: "Missing closing `)` while parsing column list.")
    }
    
    /// Parses a list of result columns from a SELECT clause in a SQL instruction.
    /// - Returns: A `ADSQLResultColumn` array representing the column definitions.
    public static func parseResultColumnList() throws -> [ADSQLResultColumn] {
        var columns: [ADSQLResultColumn] = []
        var done = false
        var state = parseState.seekColumnList
        var column = ADSQLResultColumn(with: ADSQLLiteralExpression(value: ""))
        var saveColumn = false
        
        while ADSQLParseQueue.shared.count > 0 && !done {
            // Next column definition?
            if state == .seekColumnList {
                column = ADSQLResultColumn(with: try parseExpression())
                saveColumn = true
            }
            
            // Look at the next keyword
            let key = ADSQLParseQueue.shared.lookAhead().uppercased()
            switch(key){
            case "AS":
                ADSQLParseQueue.shared.pop()
                column.columnAlias = ADSQLParseQueue.shared.pop()
                state = .inColumnList
            case ",":
                ADSQLParseQueue.shared.pop()
                state = .seekColumnList
            case "FROM":
                done = true
            default:
                break
            }
            
            // Add to collection
            if saveColumn {
                columns.append(column)
                saveColumn = false
            }
        }
        
        return columns
    }
    
    // MARK: - Expression Parsers
    /// Parses an expression in a SQL instruction.
    /// - Returns: A `ADSQLExpression` representing the expression.
    private static func parseExpression() throws -> ADSQLExpression {
        var expression: ADSQLExpression
        
        // Get the next element
        let element = ADSQLParseQueue.shared.pop()
        
        // Is this a keyword
        if let keyword = ADSQLKeyword.get(fromString: element) {
            switch(keyword) {
            case .plus:
                expression = ADSQLUnaryExpression(operation: .positive, value: try parseExpression())
            case .minus:
                expression = ADSQLUnaryExpression(operation: .negative, value: try parseExpression())
            case .notKey:
                expression = ADSQLUnaryExpression(operation: .not, value: try parseExpression())
            case .asterisk:
                expression = ADSQLLiteralExpression(value: "*")
            case .openParenthesis:
                // Create group
                expression = ADSQLUnaryExpression(operation: .group, value: try parseExpression())
                
                // The next word must be )
                try ensureNextElementMatches(keyword: ADSQLKeyword.closedParenthesis)
            case .castKey:
                // The next word must be (
                try ensureNextElementMatches(keyword: ADSQLKeyword.openParenthesis)
                let leftValue = try parseExpression()
                // The next word must be AS
                try ensureNextElementMatches(keyword: ADSQLKeyword.asKey)
                let rightValue = try parseExpression()
                // The next word must be )
                try ensureNextElementMatches(keyword: ADSQLKeyword.closedParenthesis)
                expression = ADSQLBinaryExpression(leftValue: leftValue, operation: .castTo, rightValue: rightValue)
            case .caseKey:
                expression = try parseCaseExpression()
            case .nullKey:
                expression = ADSQLLiteralExpression(value: "")
            case .emptyStringKey:
                expression = ADSQLLiteralExpression(value: "")
            default:
                // Invalid keyword
                throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found parsing expression.")
            }
        } else if let function = ADSQLFunction.get(fromString: element) {
            expression = ADSQLFunctionExpression(functionType: function, parameters: try parseFunctionParameters())
        } else {
            expression = ADSQLLiteralExpression(value: element)
        }
        
        // Continue parsing
        return try continueParsingExpression(expression)
    }
    
    /// Continues parsing an expression seeing if it is part of a larger expression.
    /// - Returns: A `ADSQLExpression` representing the expression.
    private static func continueParsingExpression(_ expression: ADSQLExpression) throws -> ADSQLExpression {
        // Anything left to process?
        if (ADSQLParseQueue.shared.count > 0) {
            // Possibly, look ahead to next element
            let nextElement = ADSQLParseQueue.shared.lookAhead().lowercased()
            switch(nextElement){
            case ";", ",", ")", "as", "from", "natural", "left", "inner", "cross", "join", "where", "group", "having", "order", "limit", "when", "then", "else", "begin", "end", "asc", "desc", "and", "or":
                // Done processing
                return expression
            default:
                // Continue on with the expression
                return try parseBinaryExpression(continuing: expression)
            }
        } else {
            // No, expression is final so return
            return expression
        }
    }
    
    /// Parses a WHERE clause properly handling AND and OR statements.
    /// - Returns a binary expression representing the WHERE clause.
    private static func parseWhereExpression() throws -> ADSQLExpression {
        var done = false
        var expression: ADSQLExpression = try parseExpression()
        
        while !done {
            let nextElement = ADSQLParseQueue.shared.lookAhead().lowercased()
            switch nextElement {
            case "and":
                // Consume key
                ADSQLParseQueue.shared.pop()
                
                // Get next expression
                let rightExpression = try parseExpression()
                
                // Assemble binary expression
                expression = ADSQLBinaryExpression(leftValue: expression, operation: .and, rightValue: rightExpression)
            case "or":
                // Consume key
                ADSQLParseQueue.shared.pop()
                
                // Get next expression
                let rightExpression = try parseExpression()
                
                // Assemble binary expression
                expression = ADSQLBinaryExpression(leftValue: expression, operation: .or, rightValue: rightExpression)
            default:
                done = true
            }
        }
        
        return expression
    }
    
    /// Parses a CASE clause in a SELECT clause in a SQL instruction.
    /// - Returns: A `ADSQLCaseExpression` representing the case clause.
    private static func parseCaseExpression() throws -> ADSQLCaseExpression {
        var state = parseState.seekCaseWhen
        var when: ADSQLExpression?
        var defaultExpression: ADSQLExpression?
        var values: [ADSQLWhenExpression] = []
        
        // Get value to compare
        let compareExpression = try parseExpression()
        
        // Search for all when...then statements
        while ADSQLParseQueue.shared.count > 0 {
            // Get the next element
            let element = ADSQLParseQueue.shared.pop()
            
            if let keyword = ADSQLKeyword.get(fromString: element) {
                switch(keyword){
                case .whenKey:
                    if state == .seekCaseWhen {
                        when = try parseExpression()
                        state = .seekCaseThen
                    } else {
                        throw ADSQLParseError.malformedSQLCommand(message: "Case statement malformed at `\(element)`.")
                    }
                case .thenKey:
                    if state == .seekCaseThen {
                        let then = try parseExpression()
                        values.append(ADSQLWhenExpression(whenValue: when!, thenValue: then))
                        state = .seekCaseWhen
                    } else {
                        throw ADSQLParseError.malformedSQLCommand(message: "Case statement malformed at `\(element)`.")
                    }
                case .elseKey:
                    if state == .seekCaseWhen {
                        defaultExpression = try parseExpression()
                        state = .seekCaseEnd
                    } else {
                        throw ADSQLParseError.malformedSQLCommand(message: "Case statement malformed at `\(element)`.")
                    }
                case .endKey:
                    if state == .seekCaseEnd {
                        if defaultExpression == nil {
                            throw ADSQLParseError.malformedSQLCommand(message: "Case statement is missing ELSE default value.")
                        } else {
                            return ADSQLCaseExpression(compareValue: compareExpression, toValues: values, defaultValue: defaultExpression!)
                        }
                    } else {
                        throw ADSQLParseError.malformedSQLCommand(message: "Case statement malformed at `\(element)`.")
                    }
                default:
                    throw ADSQLParseError.malformedSQLCommand(message: "Case statement malformed at `\(element)`.")
                }
            } else {
                throw ADSQLParseError.malformedSQLCommand(message: "Case statement malformed at `\(element)`.")
            }
        }
        
        // Error
        throw  ADSQLParseError.malformedSQLCommand(message: "Case statement missing END key.")
    }
    
    /// Parses a list of function parameter from a SELECT clause in a SQL instruction.
    /// - Returns: A `ADSQLExpression` array representing the parameters.
    private static func parseFunctionParameters() throws -> [ADSQLExpression] {
        var parameters: [ADSQLExpression] = []
        var expression: ADSQLExpression?
        
        // Process possible parameter list
        while ADSQLParseQueue.shared.count > 0 {
            // Get the next element
            let element = ADSQLParseQueue.shared.pop()
            
            if let keyword = ADSQLKeyword.get(fromString: element) {
                switch(keyword){
                case .openParenthesis:
                    let key = ADSQLParseQueue.shared.lookAhead()
                    if key != ")" {
                        expression = try parseExpression()
                    }
                case .comma:
                    if expression == nil {
                        throw ADSQLParseError.malformedSQLCommand(message: "Found a comma (`,`) but expected an expression while parsing function parameters.")
                    } else {
                        parameters.append(expression!)
                    }
                    
                    // Get next expression
                    expression = try parseExpression()
                case .closedParenthesis:
                    if expression != nil {
                        parameters.append(expression!)
                    }
                    return parameters
                default:
                    // Invalid keyword
                    throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
                }
            } else {
                throw ADSQLParseError.malformedSQLCommand(message: "At `\(element)` while parsing function parameters")
            }
        }
        
        throw ADSQLParseError.mismatchedParenthesis(message: "Missing ending `)` while parsing the list of function parameters.")
    }
    
    /// Parses a binary expression in a SQL instruction.
    /// - Parameter baseExpression: The left side of the binary instruction.
    /// - Returns: A `ADSQLExpression` representing the binary expression.
    private static func parseBinaryExpression(continuing baseExpression: ADSQLExpression) throws -> ADSQLExpression {
        var expression: ADSQLExpression
        var negate = false
        
        // Get the next element
        var element = ADSQLParseQueue.shared.pop()
        
        // Negation?
        if element.lowercased() == "not" {
            // Yes, handle and pull next element
            negate = true
            element = ADSQLParseQueue.shared.pop()
        }
        
        // Is this a keyword
        if let keyword = ADSQLKeyword.get(fromString: element) {
            switch(keyword) {
            case .plus:
                expression = ADSQLBinaryExpression(leftValue: baseExpression, operation: .addition, rightValue: try parseExpression())
            case .minus:
                expression = ADSQLBinaryExpression(leftValue: baseExpression, operation: .subtraction, rightValue: try parseExpression())
            case .asterisk:
                expression = ADSQLBinaryExpression(leftValue: baseExpression, operation: .multiplication, rightValue: try parseExpression())
            case .forwardSlash:
                expression = ADSQLBinaryExpression(leftValue: baseExpression, operation: .division, rightValue: try parseExpression())
            case .equal:
                expression = ADSQLBinaryExpression(leftValue: baseExpression, operation: .equalTo, rightValue: try parseExpression())
            case .notEqual:
                expression = ADSQLBinaryExpression(leftValue: baseExpression, operation: .notEqualTo, rightValue: try parseExpression())
            case .lessThan:
                expression = ADSQLBinaryExpression(leftValue: baseExpression, operation: .lessThan, rightValue: try parseExpression())
            case .greaterThan:
                expression = ADSQLBinaryExpression(leftValue: baseExpression, operation: .greaterThan, rightValue: try parseExpression())
            case .lessThanOrEqualTo:
                expression = ADSQLBinaryExpression(leftValue: baseExpression, operation: .lessThanOrEqualTo, rightValue: try parseExpression())
            case .greaterThanOrEqualTo:
                expression = ADSQLBinaryExpression(leftValue: baseExpression, operation: .greaterThanOrEqualTo, rightValue: try parseExpression())
            case .andKey:
                expression = ADSQLBinaryExpression(leftValue: baseExpression, operation: .and, rightValue: try parseExpression())
            case .orKey:
                expression = ADSQLBinaryExpression(leftValue: baseExpression, operation: .or, rightValue: try parseExpression())
            case .collateKey:
                expression = ADSQLBinaryExpression(leftValue: baseExpression, operation: .collate, rightValue: try parseExpression())
            case .likeKey:
                expression = ADSQLBinaryExpression(leftValue: baseExpression, operation: .like, rightValue: try parseExpression(), negate)
            case .globKey:
                expression = ADSQLBinaryExpression(leftValue: baseExpression, operation: .glob, rightValue: try parseExpression(), negate)
            case .regexpKey:
                expression = ADSQLBinaryExpression(leftValue: baseExpression, operation: .regexp, rightValue: try parseExpression(), negate)
            case .matchKey:
                expression = ADSQLBinaryExpression(leftValue: baseExpression, operation: .match, rightValue: try parseExpression(), negate)
            case .isNullKey:
                expression = ADSQLBinaryExpression(leftValue: baseExpression, operation: .equalTo, rightValue: nil, negate)
                expression = try continueParsingExpression(expression)
            case .notNullKey:
                expression = ADSQLBinaryExpression(leftValue: baseExpression, operation: .notEqualTo, rightValue: nil, negate)
                expression = try continueParsingExpression(expression)
            case .nullKey:
                expression = ADSQLBinaryExpression(leftValue: baseExpression, operation: .equalTo, rightValue: nil, negate)
                expression = try continueParsingExpression(expression)
            case .isKey:
                let nextElement = ADSQLParseQueue.shared.lookAhead().lowercased()
                if nextElement == "not" {
                    ADSQLParseQueue.shared.pop()
                    expression = ADSQLBinaryExpression(leftValue: baseExpression, operation: .notEqualTo, rightValue: try parseExpression())
                } else {
                    expression = ADSQLBinaryExpression(leftValue: baseExpression, operation: .equalTo, rightValue: try parseExpression())
                }
            case .betweenKey:
                let lowExpression = try parseExpression()
                // The next word must be AND
                try ensureNextElementMatches(keyword: .andKey)
                let highExpression = try parseExpression()
                expression = ADSQLBetweenExpression(valueIn: baseExpression, lowValue: lowExpression, highValue: highExpression, negate)
            case .inKey:
                // TODO: - Handle Sub SELECT here
                expression = ADSQLInExpression(value: baseExpression, inList: try parseFunctionParameters(), negate)
            default:
                // Invalid keyword
                throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(element)` found.")
            }
        } else {
            // Found unknown keyword
            throw ADSQLParseError.unknownKeyword(message: "`\(element)` is not a recognized SQL keyword.")
        }
        
        return expression
    }
    
    /// Parses a foreign key clause from a SQL instruction.
    /// - Returns: A `ADSQLForeignKeyExpression` representing the clause.
    private static func parseForeignKeyExpression() throws -> ADSQLForeignKeyExpression {
        let foreignKey = ADSQLForeignKeyExpression()
        
        // Get table name
        foreignKey.foreignTableName = ADSQLParseQueue.shared.pop()
        
        // Has list of column names?
        if ADSQLParseQueue.shared.lookAhead() == "(" {
            foreignKey.columnNames = try parseColumnNameList()
        }
        
        // Examine next element
        var keyword = try upcomingKey()
        switch keyword {
        case .onKey:
            // Consume next key
            ADSQLParseQueue.shared.pop()
            
            keyword = try nextKey()
            switch keyword{
            case .deleteKey:
                foreignKey.onModify = .delete
            case .updateKey:
                foreignKey.onModify = .update
            default:
                throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(keyword)` found.")
            }
            
            keyword = try nextKey()
            switch keyword {
            case .setKey:
                keyword = try nextKey()
                switch keyword {
                case .nullKey:
                    foreignKey.modifyAction = .setNull
                case .defaultKey:
                    foreignKey.modifyAction = .setDefault
                default:
                    throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(keyword)` found.")
                }
            case .cascadeKey:
                foreignKey.modifyAction = .cascade
            case .restrictKey:
                foreignKey.modifyAction = .restrict
            case .noKey:
                try ensureNextElementMatches(keyword: .actionKey)
                foreignKey.modifyAction = .noAction
            default:
                throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(keyword)` found.")
            }
        case .matchKey:
            // Consume next key
            ADSQLParseQueue.shared.pop()
            foreignKey.matchName = ADSQLParseQueue.shared.pop()
        default:
            break
        }
        
        // Examine next element
        keyword = try upcomingKey()
        switch keyword {
        case .notKey:
            // Consume next key
            ADSQLParseQueue.shared.pop()
            try ensureNextElementMatches(keyword: .deferrableKey)
            foreignKey.deferrable = false
        case .deferrableKey:
            // Consume next key
            ADSQLParseQueue.shared.pop()
            foreignKey.deferrable = true
        default:
            break
        }
        
        // Examine next element
        keyword = try upcomingKey()
        if keyword == .initiallyKey {
            // Consume next key
            ADSQLParseQueue.shared.pop()
            keyword = try nextKey()
            switch keyword {
            case .deferredKey:
                foreignKey.initiallyImmediate = false
            case .immediateKey:
                foreignKey.initiallyImmediate = true
            default:
                throw ADSQLParseError.invalidKeyword(message: "Unexpected keyword `\(keyword)` found.")
            }
        }
        
        return foreignKey
    }
    
}
