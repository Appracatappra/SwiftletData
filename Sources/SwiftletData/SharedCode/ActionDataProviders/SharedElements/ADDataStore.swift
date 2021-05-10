//
//  ADDataStore.swift
//  ActionControls
//
//  Created by Kevin Mullins on 11/9/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/**
 Represents an in-memory Data Store used to provide SQL ability to data sources that typically do not support SQL (such as JSON or XML). `ADDataStore` works with `ADTableStore` to define both the structure of the tables and to contain the rows of data stored in each table. `ADDataStore` understands a subset of the full SQL instruction set (as known by SQLite).
 
 Use the `execute` method to execute non-query SQL statements against the Data Store. For example:
 ```swift
 let datastore = ADDataStore()
 
 var sql = """
 CREATE TABLE IF NOT EXISTS parts
 (
     part_id           INTEGER   PRIMARY KEY AUTOINCREMENT,
     stock             INTEGER   DEFAULT 0   NOT NULL,
     name              TEXT,
     description       TEXT      CHECK( description != '' ),    -- empty strings not allowed
     available         BOOL      DEFAULT true
 );
 """
 
 try datastore.execute(sql)
 ```
 
 Use the `query` method to execute query SQL statements and return rows matching the result. For example:
 ```swift
 let results = try datastore.query("SELECT * FROM parts")
 print(results)
 ```
 
 - Remark: Since a `ADDataStore` holds all data in-memory, care should be taken not to overload memory. As a result, an `ADDataStore` is not a good choice for working with large amounts of data.
 */
public class ADDataStore {
    
    // MARK: - Private Variables
    /// Holds any open transaction records until they are either committed to the database or rolled back.
    private var transaction: [String:ADTableStore] = [:]
    
    /// Holds the number of transactions currently open against the Data Store.
    private var openTransactionCount: Int = 0
    
    /// Holds the name of the table that a record was last inserted into.
    private var tableLastInsertedInto = ""
    
    /// Holds the number of table rows modified by the last SQL statement.
    private var tableRowsLastModified = 0
    
    // MARK: - Properties
    /// The collection of tables stored in the Data Store.
    public var tables: [String:ADTableStore] = [:]
    
    /// Returns `true` if a transaction is currently open, else returns `false`.
    public var isTransactionOpen: Bool {
        return (openTransactionCount > 0)
    }
    
    /// Returns the row ID of the table that a record was last inserted into.
    public var lastInsertedRowID: Int {
        if let table = tables[tableLastInsertedInto] {
            return table.rows.count - 1
        } else {
            return 0
        }
    }
    
    /// Returns the number of rows modified by the last SQL command.
    public var numberOfRecordsChanged: Int {
        return tableRowsLastModified
    }
    
    // MARK: - Initializers
    /// Initializes a new instance of the Data Store.
    public init() {
        
    }
    
    /**
     Initializes a new `ADDataStore` and sets its initial properties.
     - Parameter dictionary: A `ADInstanceDictionary` to initialize the store from.
    */
    public init(fromInstance dictionary: ADInstanceDictionary) {
        self.decode(fromInstance: dictionary)
    }
    
    /**
     Initializes a new `ADDataStore` and sets its initial properties.
     
     **Swift Portable Object Notation** (SPON) data format that allows complex data models to be encoded in a portable text string that encodes not only property keys and data, but also includes type information about the encoded data. For example, using the `Address` struct above:
     
     ```swift
     @obj:Address<state$=`TX` city$=`Seabrook` addr1$=`25 Nasa Rd 1` zip$=`77586` addr2$=`Apt #123`>
     ```
     The portable, human-readable string format encodes values with a single character _type designator_ as follows:
     
     * `%` - Bool
     * `!` - Int
     * `$` - String
     * `^` - Float
     * `&` - Double
     * `*` - Embedded `NSData` or `Data` value
     
     Additionally, embedded arrays will be in the `@array[...]` format and embedded dictionaries in the `@obj:type<...>` format.
     
     - Parameter spon: A string holding the SPON encoded data to initialize the store from.
    */
    public init(fromSPON spon: String) {
        let dict = ADInstanceDictionary.decode(spon)
        self.decode(fromInstance: dict)
    }
    
    // MARK: - Functions
    /**
     Checks to see if the Data Source contains a table with the given name.
     
     - Parameter table: The name of the table to look for.
     - Returns: `true` if the Data Store contains the table, else `false`.
    */
    public func hasTable(named table: String) -> Bool {
        return tables.keys.contains(table)
    }
    
    /**
     Prepares a SQL Statement for execution by replacing instances of the `?` character with the values from the given array of parameter values. The values will be properly escaped before being added to the data stream.
     
     ## Example:
     ```swift
     let datastore = ADDataStore()
     let sql = try datastore.prepareSQL("SELECT * FROM parts WHERE part_id = ?", [4])
     ```
     
     - Parameters:
         - sql: The SQL statement to prepare for execution.
         - parameters: An array of parameter values to insert into the SQL statement.
     - Returns: The SQL statement with all `?` characters replaced with escaped values from the parameters array.
    */
    public func prepareSQL(_ sql: String, parameters: [Any]) throws -> String {
        var finalSQL = ""
        var lastChar = ""
        var inString = false
        var stringVal = ""
        var onParameter = 0
        
        // Process all characters in the SQL command
        for c in sql {
            let char = String(c)
            
            // Take action based on the character
            switch char {
            case "'":
                stringVal += "'"
                if inString {
                    if lastChar == "'" {
                        if stringVal == "''" {
                            finalSQL += stringVal
                            inString = false
                        }
                    } else {
                        finalSQL += stringVal
                        inString = false
                    }
                } else {
                    inString = true
                }
            case "?":
                if inString {
                    stringVal += char
                } else {
                    // Do we have enough parameters?
                    if onParameter >= parameters.count {
                        // No, raise error
                        throw ADSQLExecutionError.unevenNumberOfParameters(message: "There are more ? parameters specified in the SQL statement than parameters passed in when preparing the SQL statement for execution.")
                    } else if var value = parameters[onParameter] as? String {
                        // If the parameter is a string, escape single quotes and wrap the value
                        // in single quotes.
                        value = value.replacingOccurrences(of: "'", with: "''")
                        finalSQL += "'\(value)'"
                    } else if let value = parameters[onParameter] as? Data {
                        finalSQL += "'\(value.base64EncodedString())'"
                    } else if let value = parameters[onParameter] as? NSData {
                        finalSQL += "'\(value.base64EncodedString())'"
                    } else {
                        finalSQL += "\(parameters[onParameter])"
                    }
                    
                    // Increment parameter count
                    onParameter += 1
                }
            default:
                // Save to result stream
                if inString {
                    stringVal += char
                } else {
                    finalSQL += char
                }
            }
            
            // Save last char
            lastChar = char
        }
        
        // Was there a matched number of parameters?
        if onParameter < parameters.count {
            // No, throw error
            throw ADSQLExecutionError.unevenNumberOfParameters(message: "There are more parameters passed in than ? parameters specified in the SQL statement when preparing it for execution.")
        }
        
        // Return SQL with all parameters in place
        return finalSQL
    }
    
    /**
     Executes a non-query SQL statement against the Data Store. `ADDataStore` understands a subset of the full SQL instruction set (as known by SQLite) and as such, creating indexes, triggers, views and named save points are not currently supported.
     
     ## Example:
     ```swift
     let datastore = ADDataStore()
     
     var sql = """
     CREATE TABLE IF NOT EXISTS parts
     (
         part_id           INTEGER   PRIMARY KEY AUTOINCREMENT,
         stock             INTEGER   DEFAULT 0   NOT NULL,
         name              TEXT,
         description       TEXT      CHECK( description != '' ),    -- empty strings not allowed
         available         BOOL      DEFAULT true
     );
     """
     
     try datastore.execute(sql)
     ```
     
     - Parameters:
         - sql: The SQL statements to execute against the Data Store.
         - parameters: An array of optional parameter values used to replace any `?` characters in the SQL Statement.
     */
    public func execute(_ sql: String, parameters: [Any] = []) throws {
        let command = (parameters.count == 0) ? sql : try prepareSQL(sql, parameters: parameters)
        let instructions = try ADSQLParser.parse(command)
        
        // Process all instructions
        for instruction in instructions {
            // Take action based on the instruction type
            if let command = instruction as? ADSQLCreateTableInstruction {
                try createTable(command)
            } else if let command = instruction as? ADSQLAlterTableInstruction {
                try alterTable(command)
            } else if instruction is ADSQLCreateIndexInstruction {
                throw ADSQLExecutionError.unsupportedCommand(message: "ADDataStore does not support creating indexes.")
            } else if instruction is ADSQLCreateTriggerInstruction {
                throw ADSQLExecutionError.unsupportedCommand(message: "ADDataStore does not support creating triggers")
            } else if instruction is ADSQLCreateViewInstruction {
                throw ADSQLExecutionError.unsupportedCommand(message: "ADDataStore does not support creating views")
            } else if instruction is ADSQLSelectInstruction {
                throw ADSQLExecutionError.unsupportedCommand(message: "SELECT command is invalid in `execute`, call `query` instead.")
            } else if let command = instruction as? ADSQLDropInstruction {
                try drop(command)
            } else if let command = instruction as? ADSQLInsertInstruction {
                tableLastInsertedInto = command.tableName
                try insert(command)
            } else if let command = instruction as? ADSQLTransactionInstruction {
                // Take action based on the action type
                switch command.action {
                case .beginDeferred, .beginExclusive, .beginImmediate:
                    beginTransaction()
                case .commit:
                    commitTransaction()
                case .rollback:
                    rollbackTransaction()
                case .savepoint, .releaseSavepoint:
                    throw ADSQLExecutionError.unsupportedCommand(message: "ADDataStore does not support creating named savepoint transactions.")
                }
            } else if let command = instruction as? ADSQLUpdateInstruction {
                try update(command)
            } else if let command = instruction as? ADSQLDeleteInstruction {
                try delete(command)
            } else {
                throw ADSQLExecutionError.invalidCommand(message: "Instruction `\(instruction)` not valid in an EXECUTE call.")
            }
        }
    }
    
    /**
     Use the `query` method to execute query SQL statements and return rows matching the result. `ADDataStore` understands a subset of the full SQL instruction set (as known by SQLite), however, most common **SELECT** statements should work as expected.
     
     ## Example:
     ```swift
     let results = try datastore.query("SELECT * FROM parts WHERE part_id = ?", [2])
     print(results)
     ```
     
     - Parameters:
         - sql: The SQL statements to execute against the Data Store.
         - parameters: An array of optional parameter values used to replace any `?` characters in the SQL Statement.
     - Returns: An `ADRecordSet` containing all of the rows from the Data Store matching the given query or an empty set if no rows matched.
     */
    public func query(_ sql: String, parameters: [Any] = []) throws -> ADRecordSet {
        var records: ADRecordSet = []
        let command = (parameters.count == 0) ? sql : try prepareSQL(sql, parameters: parameters)
        let instructions = try ADSQLParser.parse(command)
        
        // Process all instructions
        for instruction in instructions {
            if let command = instruction as? ADSQLSelectInstruction {
                records = try select(command)
            } else {
                throw ADSQLExecutionError.invalidCommand(message: "Instruction `\(instruction)` not valid in a QUERY call.")
            }
        }
        
        // Return results
        return records
    }
    
    /// Stars a new SQL Transaction against the Data Store.
    private func beginTransaction() {
        // Is a transaction already open?
        if isTransactionOpen {
            return
        }
        
        // Save a snapshot of the database
        transaction = tables
        openTransactionCount += 1
    }
    
    /// Ends a currenlty active SQL Transaction and returns the Data Store to the state it was in before the transaction started.
    private func rollbackTransaction() {
        // Is a transaction open?
        if !isTransactionOpen {
            return
        }
        
        // Rollback to snapshot
        tables = transaction
        openTransactionCount -= 1
        if openTransactionCount == 0 {
            transaction = [:]
        }
    }
    
    /// Ends a currently active SQL Transaction and writes all of the changes made into the Data Store.
    private func commitTransaction() {
        // Close open transaction and finalize data store
        openTransactionCount -= 1
        if openTransactionCount == 0 {
            transaction = [:]
        }
    }
    
    /**
     Creates a new table in the Data Store based on the given criteria.
     - Parameter instruction: A `ADSQLCreateTableInstruction` defining the table to create.
    */
    private func createTable(_ instruction: ADSQLCreateTableInstruction) throws {
        
        // Is the table already on file?
        if hasTable(named: instruction.name) {
            if instruction.ifNotExists {
                return
            } else {
                throw ADSQLExecutionError.duplicateTable(message: "Table `\(instruction.name)` already exists in the data store.")
            }
        }
        
        // Build table storage
        let table = ADTableStore(tableName: instruction.name)
        
        // Populate the table schema
        var id = 0
        for column in instruction.columns {
            // Build a schema for this column
            let columnDef = ADColumnSchema(id: id, name: column.name, type: column.type)
            
            // Populate any constraints
            for constraint in column.constraints {
                // Take action based on the constraint type
                switch constraint.type {
                case .primaryKeyAsc, .primaryKeyDesc:
                    columnDef.isPrimaryKey = true
                    columnDef.autoIncrement = constraint.autoIncrement
                case .notNull:
                    columnDef.allowsNull = false
                case .unique:
                    columnDef.isKeyUnique = true
                case .check:
                    columnDef.checkExpression = constraint.expression
                case .defaultValue:
                    columnDef.defaultValue = try constraint.expression?.evaluate(forRecord: nil)
                case .collate:
                    throw ADSQLExecutionError.unsupportedCommand(message: "ADDataStore does not support collate constraints on table columns.")
                case .foreignKey:
                    throw ADSQLExecutionError.unsupportedCommand(message: "ADDataStore does not support foreign key constraints on table columns.")
                }
            }
            
            // Save column and increment ID
            table.schema.add(value: columnDef)
            id += 1
        }
        
        // Create from a select statement?
        if let selectStatement = instruction.selectStatement {
            let rows = try select(selectStatement)
            if rows.count > 0 {
                let row = rows[0]
                var id = 0
                for key in row.keys {
                    if !table.schema.hasColumn(named: key) {
                        // Build a schema for this column
                        let columnDef = ADColumnSchema(id: id, name: key, type: .noneType)
                        
                        // Save column and increment ID
                        table.schema.add(value: columnDef)
                        id += 1
                    }
                }
                
                // Copy over data
                table.rows = rows
            } else {
                throw ADSQLExecutionError.noRowsReturned(message: "The SELECT clause used to create table `\(instruction.name)` returned no rows.")
            }
        }
        
        // Add table to data store
        tables[instruction.name] = table
    }
    
    /**
     Modifies a table in the Data Store.
     - Parameter instruction: A `ADSQLAlterTableInstruction` defining the table to modify and the changes to make.
     */
    private func alterTable(_ instruction: ADSQLAlterTableInstruction) throws {
        // Is the requested table available?
        if !hasTable(named: instruction.name) {
            throw ADSQLExecutionError.unknownTable(message: "ADDataStore does not containt a table named `\(instruction.name)`.")
        }
        
        // Renaming a table?
        if !instruction.renameTo.isEmpty {
            // Ensure the table name doesn't already exist
            if hasTable(named: instruction.renameTo) {
                throw ADSQLExecutionError.duplicateTable(message: "ADDataStore alreay contains a table named `\(instruction.renameTo)`.")
            }
            
            // Pull existing table
            let table = tables[instruction.name]!
            tables.removeValue(forKey: instruction.name)
            
            // Change name and resave
            table.schema.name = instruction.renameTo
            tables[instruction.renameTo] = table
        } else if let column = instruction.column {
            // Grab table and next column ID
            let table = tables[instruction.name]!
            let id = table.schema.column.count
            
            // Build a schema for this column
            let columnDef = ADColumnSchema(id: id, name: column.name, type: column.type)
            
            // Populate any constraints
            for constraint in column.constraints {
                // Take action based on the constraint type
                switch constraint.type {
                case .primaryKeyAsc, .primaryKeyDesc:
                    throw ADSQLExecutionError.syntaxError(message: "ALTER TABLE ADD COLUMN cannot create a PRIMARY KEY column.")
                case .notNull:
                    columnDef.allowsNull = false
                case .unique:
                    throw ADSQLExecutionError.syntaxError(message: "ALTER TABLE ADD COLUMN cannot create a UNIQUE value column.")
                case .check:
                    columnDef.checkExpression = constraint.expression
                case .defaultValue:
                    columnDef.defaultValue = try constraint.expression?.evaluate(forRecord: nil)
                case .collate:
                    throw ADSQLExecutionError.unsupportedCommand(message: "ADDataStore does not support collate constraints on table columns.")
                case .foreignKey:
                    throw ADSQLExecutionError.unsupportedCommand(message: "ADDataStore does not support foreign key constraints on table columns.")
                }
            }
            
            // Save column to table
            table.schema.add(value: columnDef)
        } else {
            throw ADSQLExecutionError.syntaxError(message: "Malformed ALTER TABLE instruction neither renamed the table or added a new column.")
        }
    }
    
    /**
     Drops a table from the Data Store.
     - Parameter instruction: A `ADSQLDropInstruction` defining the table to drop.
    */
    private func drop(_ instruction: ADSQLDropInstruction) throws {
        
        // Only tables are supported
        if instruction.action != .table {
            throw ADSQLExecutionError.unsupportedCommand(message: "ADDataStore only supports dropping tables.")
        }
        
        // Does the table exist?
        if !hasTable(named: instruction.itemName) {
            if instruction.ifExists {
                return
            } else {
                throw ADSQLExecutionError.unknownTable(message: "ADDataStore does not containt a table named `\(instruction.itemName)`.")
            }
        }
        
        // Remove table from data store
        tables.removeValue(forKey: instruction.itemName)
        
    }
    
    /**
     Inserts a record into a table in the Data Store.
     - Parameter instruction: A `ADSQLInsertInstruction` defining the record to insert.
    */
    private func insert(_ instruction: ADSQLInsertInstruction) throws {
        
        // Does the table exist?
        if !hasTable(named: instruction.tableName) {
            throw ADSQLExecutionError.unknownTable(message: "ADDataStore does not containt a table named `\(instruction.tableName)`.")
        }
        
        // Access table
        let table = tables[instruction.tableName]!
        
        // Flooding new record with default values?
        if instruction.defaultValues {
            var record = ADRecord()
            for column in table.schema.column {
                if let value = column.defaultValue {
                    record[column.name] = value
                } else {
                    record[column.name] = ""
                }
            }
            try table.insertRow(record, action: instruction.action)
            return
        }
        
        // Inserting from another table?
        if let selectCommand = instruction.selectStatement {
            // Attempt to get the source records
            let sourceRows = try select(selectCommand)
            
            if instruction.columnNames.count > 0 {
                // Do the column names match the number of values specified?
                if instruction.columnNames.count != selectCommand.columns.count {
                    throw ADSQLExecutionError.syntaxError(message: "The number of columns specified don't match the number of supplied values for the INSERT...SELECT command.")
                }
                
                // Process all rows of the selected records
                for row in sourceRows {
                    // Populate record with default values first
                    var record = ADRecord()
                    for column in table.schema.column {
                        if column.autoIncrement && column.type == .integerType {
                            record[column.name] = table.nextAutoIncrementingID
                        } else {
                            if let value = column.defaultValue {
                                record[column.name] = value
                            } else {
                                record[column.name] = ""
                            }
                        }
                    }
                    
                    // Add values from select statement
                    for n in 0..<instruction.columnNames.count {
                        let destinationColumn = instruction.columnNames[n]
                        if let sourceColumn = try selectCommand.columns[n].expression.evaluate(forRecord: record) as? String {
                            // Copy over value
                            record[destinationColumn] = row[sourceColumn]
                        } else {
                            throw ADSQLExecutionError.syntaxError(message: "When processing an INSERT...SELECT command the specified column name did not evaluate to a String value.")
                        }
                    }
                    
                    // Attempt to add record to data store
                    try table.insertRow(record, action: instruction.action)
                }
            } else {
                // Process all rows of the selected records
                for row in sourceRows {
                    // Populate record with default values first
                    var record = ADRecord()
                    for column in table.schema.column {
                        if column.autoIncrement && column.type == .integerType {
                            record[column.name] = table.nextAutoIncrementingID
                        } else {
                            if let value = column.defaultValue {
                                record[column.name] = value
                            } else {
                                record[column.name] = ""
                            }
                        }
                    }
                    
                    // Add values from select statement
                    for (key, value) in row {
                        // Add values to record
                        record[key] = value
                    }
                    
                    // Attempt to add record to data store
                    try table.insertRow(record, action: instruction.action)
                }
            }
        } else if instruction.columnNames.count > 0 {
            // Do the column names match the number of values specified?
            if instruction.columnNames.count != instruction.values.count {
                throw ADSQLExecutionError.syntaxError(message: "The number of columns specified don't match the number of supplied values for the INSERT command.")
            }
            
            // Populate record with default values first
            var record = ADRecord()
            for column in table.schema.column {
                if column.autoIncrement && column.type == .integerType {
                    record[column.name] = table.nextAutoIncrementingID
                } else {
                    if let value = column.defaultValue {
                        record[column.name] = value
                    } else {
                        record[column.name] = ""
                    }
                }
            }
            
            // Set provided values
            var n = 0
            for column in instruction.columnNames {
                record[column] = try instruction.values[n].evaluate(forRecord: record)
                n += 1
            }
            
            // Attempt to add record to data store
            try table.insertRow(record, action: instruction.action)
        } else {
            // Assemble record
            var record = ADRecord()
            var n = 0
            for column in table.schema.column {
                record[column.name] = try instruction.values[n].evaluate(forRecord: record)
                n += 1
            }
            
            // Attempt to add record to data store
            try table.insertRow(record, action: instruction.action)
        }
    }
    
    /**
     Updates a record in a table in the Data Store with new values.
     - Parameter instruction: A `ADSQLUpdateInstruction` defining the record to update.
     */
    private func update(_ instruction: ADSQLUpdateInstruction) throws {
        
        var requiresUpdate = false
        
        // Does the table exist?
        if !hasTable(named: instruction.tableName) {
            throw ADSQLExecutionError.unknownTable(message: "ADDataStore does not containt a table named `\(instruction.tableName)`.")
        }
        
        // Access table
        let table = tables[instruction.tableName]!
        
        // Ensure the table has the requested columns being updated
        for clause in instruction.setClauses {
            if !table.schema.hasColumn(named: clause.columnName) {
                throw ADSQLExecutionError.unknownColumn(message: "Table `\(table.schema.name)` does not contain column `\(clause.columnName)`.")
            }
        }
        
        // Starting a transaction?
        if instruction.action == .updateOrRollback {
            beginTransaction()
        }
        
        // Scan over all rows
        tableRowsLastModified = 0
        for n in 0..<table.rows.count {
            // Grab current record
            var record = table.rows[n]
            
            // Has where clause?
            if let test = instruction.whereExpression {
                if let evaluation = try test.evaluate(forRecord: record) {
                    if let valid = evaluation as? Bool {
                        requiresUpdate = valid
                    } else {
                        throw ADSQLExecutionError.syntaxError(message: "WHERE clause should evaluate to a boolean value but returned `\(evaluation)` instead.")
                    }
                } else {
                    requiresUpdate = false
                }
            } else {
                requiresUpdate = true
            }
            
            // Does the record require update?
            if requiresUpdate {
                // Count rows modified
                tableRowsLastModified += 1
                
                // Yes, write new values to each field
                for clause in instruction.setClauses {
                    record[clause.columnName] = try clause.expression?.evaluate(forRecord: record)
                }
                
                // Verify record
                if let issue = table.validateRecord(record) {
                    // An error occurred, handle it based on the requested transaction state.
                    switch instruction.action {
                    case .updateOrIgnore:
                        // Ignore error and move to next record
                        break
                    case .updateOrAbort:
                        // Stop processing updates
                        return
                    case .updateOrRollback:
                        // Rollback transaction and abort
                        rollbackTransaction()
                        return
                    default:
                        // Pass error upstream
                        throw issue
                    }
                } else {
                    // Record was good, save
                    table.rows[n] = record
                }
            }
        }
        
        // Closing a transaction?
        if instruction.action == .updateOrRollback {
            commitTransaction()
        }
    }
    
    /**
     Deletes a record from a table in the Data Store.
     - Parameter instruction: A `ADSQLDeleteInstruction` defining the record to delete.
    */
    private func delete(_ instruction: ADSQLDeleteInstruction) throws {
        
        var discardRecord = false
        
        // Does the table exist?
        if !hasTable(named: instruction.tableName) {
            throw ADSQLExecutionError.unknownTable(message: "ADDataStore does not containt a table named `\(instruction.tableName)`.")
        }
        
        // Access table
        let table = tables[instruction.tableName]!
        
        // Has where clause?
        if let whereClause = instruction.whereExpression {
            // Yes, scan for records to delete
            tableRowsLastModified = 0
            for n in (0..<table.rows.count).reversed() {
                // Grab current record
                let record = table.rows[n]
                
                // Process where clause
                if let evaluation = try whereClause.evaluate(forRecord: record) {
                    if let valid = evaluation as? Bool {
                        discardRecord = valid
                    } else {
                        throw ADSQLExecutionError.syntaxError(message: "WHERE clause should evaluate to a boolean value but returned `\(evaluation)` instead.")
                    }
                } else {
                    discardRecord = false
                }
                    
                // Remove?
                if discardRecord {
                    // Count rows modified
                    tableRowsLastModified += 1
                    
                    // Yes, remove current item
                    table.rows.remove(at: n)
                }
            }
        } else {
            // Save modification count
            tableRowsLastModified = table.rows.count
            
            // No, remove all rows
            table.rows = []
        }
    }
    
    /**
     Selects data from the Data Store based on a given set of instruction parse from a SQL command string.
     - Parameter instruction: A `ADSQLSelectInstruction` defining the data to select.
     - Returns: A `ADRecordSet` with the requested data or an empty set if no data was found.
    */
    private func select(_ instruction: ADSQLSelectInstruction) throws -> ADRecordSet {
        var records: ADRecordSet = []
        var include = false
        var hasAggregate = false
        
        // Make instruction mutable
        var instruction = instruction
        
        // Verify that the join is valid
        try verifyJoin(instruction.fromSouce)
        
        // Get joined source rows
        let rows = try accumulateSourceRecords(fromJoin: instruction.fromSouce)
        
        // Does any of the result columns include an aggregate?
        var colNum = 1
        for column in instruction.columns {
            let isAggregate = containsAggregate(expression: column.expression)
            if isAggregate {
                hasAggregate = true
                
                // Add column to the GROUP BY instruction
                if column.columnAlias.isEmpty {
                    instruction.groupByColumns.append("Col\(colNum)")
                } else {
                    instruction.groupByColumns.append(column.columnAlias)
                }
            }
            colNum += 1
        }
        
        // Does the where expression contain an aggregate?
        if !hasAggregate {
            if let whereClause = instruction.whereExpression {
                hasAggregate = containsAggregate(expression: whereClause)
            }
        }
        
        // Does the having expression contain an aggregate?
        if !hasAggregate {
            if let having = instruction.havingExpression {
                hasAggregate = containsAggregate(expression: having)
            }
        }
        
        // Requires an accumulation pass?
        if hasAggregate {
            // Enable accumulation of aggregation values
            ADSQLFunctionExpression.accumulate = true
            
            // Yes, make a pass through the data to accumulate aggregates
            for row in rows {
                // Has where clause?
                if let whereClause = instruction.whereExpression {
                    if let evaluation = try whereClause.evaluate(forRecord: row) {
                        if let valid = evaluation as? Bool {
                            include = valid
                        } else {
                            throw ADSQLExecutionError.syntaxError(message: "WHERE clause should evaluate to a boolean value but returned `\(evaluation)` instead.")
                        }
                    } else {
                        include = false
                    }
                } else {
                    include = true
                }

                // Include in results?
                if include {
                    for column in instruction.columns {
                        try column.expression.evaluate(forRecord: row)
                    }
                }
            }
            
            // Set aggregate function into report-only mode for next pass.
            ADSQLFunctionExpression.accumulate = false
        }
        
        // Accumulate requested rows and columns from joined source
        for row in rows {
            // Has where clause?
            if let whereClause = instruction.whereExpression {
                if let evaluation = try whereClause.evaluate(forRecord: row) {
                    if let valid = evaluation as? Bool {
                        include = valid
                    } else {
                        throw ADSQLExecutionError.syntaxError(message: "WHERE clause should evaluate to a boolean value but returned `\(evaluation)` instead.")
                    }
                } else {
                    include = false
                }
            } else {
                include = true
            }
            
            // Include in results?
            if include {
                var record: ADRecord = [:]
                var colNum = 0
                
                // Include requested columns
                for column in instruction.columns {
                    if let value = try column.expression.evaluate(forRecord: row) {
                        if ADUtilities.compare(value, .equalTo, "*") {
                            // Return all columns
                            record = row
                        } else if ADUtilities.compare(value, .contains, ".*") {
                            // Selecting all columns from one of the sub tables
                            let path = value as! String
                            let parts = path.components(separatedBy: ".")
                            let tableName = parts.first! + "."
                            
                            // Scan all returned columns for requested columns
                            for key in row.keys {
                                if key.contains(tableName) {
                                    record[key] = row[key]
                                }
                            }
                        } else {
                            colNum += 1
                            var key = ""
                            
                            // Compute column name
                            if !column.columnAlias.isEmpty {
                                key = column.columnAlias
                            } else if let literal = column.expression as? ADSQLLiteralExpression {
                                key = literal.value
                            } else {
                                key = "Col\(colNum)"
                            }
                            
                            // Save value under key
                            record[key] = value
                        }
                    }
                }
                
                // Any columns copied to the record?
                if record.count > 0 {
                    // Yes, include it in the results
                    records.append(record)
                }
            }
        }
        
        // Apply grouping
        records = try groupRecords(records, on: instruction.groupByColumns, having: instruction.havingExpression)
        
        // Apply sort
        records = try sortRecords(records, by: instruction.orderBy)
        
        // Apply limits and offset
        records = limitRecords(records, to: instruction.limit, startingWithRow: instruction.offset)
        
        // Return results
        return records
    }
    
    /**
     Check to see if the given expression contains a call to an aggregate function.
     - Parameter expression: A `ADSQLExpression` to test for aggregate functions.
     - Returns: `true` if the expression calls an aggregate function, else `false`.
    */
    private func containsAggregate(expression: ADSQLExpression) -> Bool {
        var hasAggregate = false
        
        if let function = expression as? ADSQLFunctionExpression {
            if function.isAggregate {
                hasAggregate = true
            }
        } else if let binary = expression as? ADSQLBinaryExpression {
            hasAggregate = containsAggregate(expression: binary.leftValue)
            if let rightValue = binary.rightValue {
                hasAggregate = hasAggregate || containsAggregate(expression: rightValue)
            }
        }
        
        return hasAggregate
    }
    
    /**
     Limits the set of records returned by a select statement based on the given offset from the top of the returned set and record count.
     - Parameters:
         - records: The raw set of records returned by a select.
         - limit: The maximum number of records to return.
         - offset: The first record (offset from the top of the set) to return.
     - Returns: The returned records limited to the given maximum number and offset.
    */
    private func limitRecords(_ records: ADRecordSet, to limit: Int, startingWithRow offset: Int) -> ADRecordSet {
        
        // Any limits to apply?
        if (limit < 0 && offset < 0) || records.count < 1 {
            // No, return original set
            return records
        }
        
        // Build subset
        var subset: ADRecordSet = []
        
        // Apply limits and offset
        var n = (offset < 0) ? 0 : offset
        let max = (limit < 0) ? records.count : limit
        while n < records.count && subset.count < max {
            subset.append(records[n])
            n += 1
        }
        
        // Return pared down results
        return subset
    }
    
    /**
     Sorts a set of records by the given set of order by clauses.
     - Parameters:
         - records: The raw set of records to sort.
         - order: An array of `ADSQLOrderByClause` defining how to sort the records.
     - Returns: The record set sorted in the requested order.
    */
    private func sortRecords(_ records: ADRecordSet, by order:[ADSQLOrderByClause]) throws -> ADRecordSet {
        
        // Apply sort?
        if order.count < 1 || records.count < 2 {
            // No, return unsorted set
            return records
        }
        
        // Build ordered set
        var orderedSet = records
        
        // Apply all sorts
        for sort in order {
            let ascending = (sort.order == .ascending)
            let record = records[0]
            if record.keys.contains(sort.columnName) {
                orderedSet = quicksort(orderedSet, on: sort.columnName, ascending)
            } else {
                throw ADSQLExecutionError.unknownColumn(message: "Unable to apply GROUP BY statment because the result set does not contain column `\(sort.columnName)`.")
            }
        }
        
        // Return results
        return orderedSet
    }
    
    /**
     Groups the rows of data from the given record set on the given columns using the given limits.
     - Parameters:
         - records: The set of records to group.
         - columns: An array of column names to group on.
         - limit: An expression used to control how records are grouped.
     - Returns: The record set with the rows grouped in the requested order.
    */
    private func groupRecords(_ records: ADRecordSet, on columns: [String], having limit: ADSQLExpression?) throws -> ADRecordSet {
        
        // Apply grouping?
        if columns.count < 1 || records.count < 2 {
            // No, return unsorted set
            return records
        }
        
        // Build ordered set
        var orderedSet = records
        
        // Apply all sorts
        for column in columns {
            // Ensure the recordset contains the requested column
            let record = records[0]
            if record.keys.contains(column) {
                orderedSet = quicksort(orderedSet, on: column, true)
            } else {
                throw ADSQLExecutionError.unknownColumn(message: "Unable to apply GROUP BY statment because the result set does not contain column `\(column)`.")
            }
        }
        
        // Build grouped set
        var groupedSet: ADRecordSet = []
        
        // Thin set down to group record
        let column = columns.last!
        var last: ADRecord = [:]
        var include = false
        for record in orderedSet {
            // Apply having limit
            if let having = limit {
                if let evaluation = try having.evaluate(forRecord: record) {
                    if let valid = evaluation as? Bool {
                        include = valid
                    } else {
                        throw ADSQLExecutionError.syntaxError(message: "HAVING clause should evaluate to a boolean value but returned `\(evaluation)` instead.")
                    }
                } else {
                    include = false
                }
            } else {
                include = true
            }
            
            // Included in set?
            if include {
                // Still in the same group?
                if let v1 = last[column] {
                    if let v2 = record[column] {
                        if ADUtilities.compare(v1, .notEqualTo, v2) {
                            if last.count > 0 {
                                groupedSet.append(last)
                            }
                        }
                    }
                }
                
                // Save last column
                last = record
            }
        }
        
        // Finalize set
        if last.count > 0 {
            groupedSet.append(last)
        }
        
        // Return results
        return groupedSet
    }
    
    /**
     Initializes a quicksort against the given set of records on the given column in the given order.
     
     - Parameters:
         - records: The set of records to sort.
         - column: The name of the column to sort on.
         - ascending: If `true` the records are sorted in ascending order, else if `false`, they are sorted in descending order.
     - Returns: The records sorted in the requested order.
    */
    private func quicksort(_ records: ADRecordSet, on column: String, _ ascending: Bool = true) -> ADRecordSet {
        return quicksort(records, on: column, ascending, 0, records.count - 1)
    }
    
    /**
     Runs a quicksort against the given set of records on the given column in the given order.
     
     - Parameters:
         - records: The set of records to sort.
         - column: The name of the column to sort on.
         - ascending: If `true` the records are sorted in ascending order, else if `false`, they are sorted in descending order.
         - low: The record to start the sort on.
         - high: The record to end the sort on.
     - Returns: The records sorted in the requested order.
     */
    private func quicksort(_ records: ADRecordSet, on column: String, _ ascending: Bool, _ low: Int, _ high: Int) -> ADRecordSet {
        
        // Build ordered set
        var orderedSet = records
        
        // Done?
        if low < high {
            // No, apply sort
            var p = 0
            (p, orderedSet) = partition(orderedSet, on: column, ascending, low, high)
            orderedSet = quicksort(orderedSet, on: column, ascending, low, p - 1)
            orderedSet = quicksort(orderedSet, on: column, ascending, p + 1, high)
        }
        
        // Return results
        return orderedSet
    }
    
    /**
     Calculates a partition for a quicksort against the given set of records on the given column in the given order.
     
     - Parameters:
         - records: The set of records to sort.
         - column: The name of the column to sort on.
         - ascending: If `true` the records are sorted in ascending order, else if `false`, they are sorted in descending order.
         - low: The record to start the sort on.
         - high: The record to end the sort on.
     - Returns: The partition point and the records sorted in the requested order.
     */
    private func partition(_ records: ADRecordSet, on column: String, _ ascending: Bool, _ low: Int, _ high: Int) -> (Int, ADRecordSet) {
        
        // Build ordered set
        var orderedSet = records
        let pivot = orderedSet[high]
        var i = low - 1
        let comparison = (ascending) ? ADUtilities.Comparison.lessThan : ADUtilities.Comparison.greaterThan
        
        for j in low..<high {
            let record = orderedSet[j]
            if let v1 = record[column] {
                if let v2 = pivot[column] {
                    if ADUtilities.compare(v1, comparison, v2) {
                        i += 1
                        orderedSet[j] = orderedSet[i]
                        orderedSet[i] = record
                    }
                }
            }
        }
        
        let record = orderedSet[i + 1]
        if let v1 = pivot[column] {
            if let v2 = record[column] {
                if ADUtilities.compare(v1, comparison, v2) {
                    orderedSet[i + 1] = pivot
                    orderedSet[high] = record
                }
            }
        }
        
        // Return results
        return (i + 1, orderedSet)
    }
    
    /**
     Verifies that a join between two or more tables in valid and throws an error if it is not.
     - Parameter join: A `ADSQLJoinClause` defining the join.
    */
    private func verifyJoin(_ join: ADSQLJoinClause) throws {
        
        // Does the parent table exist?
        if !hasTable(named: join.parentTable) {
            throw ADSQLExecutionError.unknownTable(message: "ADDataStore does not containt a table named `\(join.parentTable)`.")
        }
        
        // Is there a child table and does it exist?
        if !join.childTable.isEmpty {
            if !hasTable(named: join.childTable) {
                throw ADSQLExecutionError.unknownTable(message: "ADDataStore does not containt a table named `\(join.childTable)`.")
            }
        }
        
        // Is the child table part of a join itself?
        if let subJoin = join.childJoin {
            // Yes, verify that join too
            try verifyJoin(subJoin)
        }
    }
    
    /**
     Removes any full pathing information from the column names of the given record.
     - Parameter source: The record to strip paths from.
     - Returns: The record with all paths stripped from the column names.
    */
    private func stripPaths(from source: ADRecord) -> ADRecord {
        var record: ADRecord = [:]
        
        // Process all columns in the source record
        for (key, val) in source {
            // Contains path?
            if key.contains(".") {
                // Yes, split into parts and save under raw column name
                let parts = key.components(separatedBy: ".")
                record[parts.last!] = val
            } else {
                // No, just copy as is
                record[key] = val
            }
        }
        
        return record
    }
    
    /**
     Pulls together all of the data represented by the joining of one or more tables. If a join is not taking place, the data from the parent table only is returned.
     - Parameter join: A `ADSQLJoinClause` defining the join.
     - Returns: A `ADRecordSet` representing all of the data in the join.
    */
    private func accumulateSourceRecords(fromJoin join: ADSQLJoinClause) throws -> ADRecordSet {
        var processAs = ADSQLJoinClause.JoinType.none
        
        // Take action based on the join type
        switch join.type {
        case .none:
            // Not a join, simply return source table's records
            return tables[join.parentTable]!.rows
        case .natural:
            // Find all intersecting column names
            join.columnList = []
            let parentTable = tables[join.parentTable]!
            let childTable = tables[join.childTable]!
            for parentColumn in parentTable.schema.column {
                if childTable.schema.hasColumn(named: parentColumn.name) {
                    // Found intersection, record
                    join.columnList.append(parentColumn.name)
                }
            }
            
            // Any matches found?
            if join.columnList.count > 0 {
                processAs = .inner
            } else {
                processAs = .cross
            }
        case.inner:
            // Has join criteria?
            if join.onExpression == nil && join.columnList.count == 0 {
                processAs = .cross
            } else {
                processAs = .inner
            }
        case .cross:
            processAs = .cross
        case .leftOuter:
            // Has join criteria?
            if join.onExpression == nil && join.columnList.count == 0 {
                processAs = .cross
            } else {
                processAs = .leftOuter
            }
            break
        }
        
        // Access the parts of the join
        var records: ADRecordSet = []
        let parentTable = tables[join.parentTable]!
        let childTable = tables[join.childTable]!
        
        // Handle based on the process requested
        switch processAs {
        case .inner:
            // Has on or using statement?
            if let onClause = join.onExpression {
                // Accumulate records from parent table
                for parentRecord in parentTable.rows {
                    // Build new record
                    var record: ADRecord = [:]
                    
                    // Accumulate parent columns
                    for (key, col) in parentRecord {
                        let id = "\(join.parentTableAlias.isEmpty ? join.parentTable : join.parentTableAlias).\(key)"
                        record[id] = col
                    }
                    
                    // Has matching child records?
                    let childRecords = try childTable.findRows(matching: record, on: onClause, alias: join.childTableAlias)
                    for childRecord in childRecords {
                        var joinedRecord = record
                        
                        // Include child columns
                        for (key, col) in childRecord {
                            let id = "\(join.childTableAlias.isEmpty ? join.childTable : join.childTableAlias).\(key)"
                            joinedRecord[id] = col
                        }
                        
                        // Save match
                        records.append(joinedRecord)
                    }
                }
            } else {
                // Accumulate records from parent table
                for parentRecord in parentTable.rows {
                    // Build new record
                    var record: ADRecord = [:]
                    
                    // Accumulate parent columns
                    for (key, col) in parentRecord {
                        let id = "\(join.parentTableAlias.isEmpty ? join.parentTable : join.parentTableAlias).\(key)"
                        record[id] = col
                    }
                    
                    // Has matching child records?
                    let childRecords = childTable.findRows(matching: parentRecord, onColumns: join.columnList)
                    for childRecord in childRecords {
                        var joinedRecord = record
                        
                        // Include child columns
                        for (key, col) in childRecord {
                            let id = "\(join.childTableAlias.isEmpty ? join.childTable : join.childTableAlias).\(key)"
                            joinedRecord[id] = col
                        }
                        
                        // Save match
                        records.append(joinedRecord)
                    }
                }
            }
        case .leftOuter:
            // Has on or using statement?
            if let onClause = join.onExpression {
                // Accumulate records from parent table
                for parentRecord in parentTable.rows {
                    // Build new record
                    var record: ADRecord = [:]
                    
                    // Accumulate parent columns
                    for (key, col) in parentRecord {
                        let id = "\(join.parentTableAlias.isEmpty ? join.parentTable : join.parentTableAlias).\(key)"
                        record[id] = col
                    }
                    
                    // Has matching child records?
                    let childRecords = try childTable.findRows(matching: record, on: onClause, alias: join.childTableAlias)
                    if childRecords.count > 0 {
                        for childRecord in childRecords {
                            var joinedRecord = record
                            
                            // Include child columns
                            for (key, col) in childRecord {
                                let id = "\(join.childTableAlias.isEmpty ? join.childTable : join.childTableAlias).\(key)"
                                joinedRecord[id] = col
                            }
                            
                            // Save match
                            records.append(joinedRecord)
                        }
                    } else {
                        var joinedRecord = record
                        
                        // Pad record with empty child columns
                        for col in childTable.schema.column {
                            let id = "\(join.childTableAlias.isEmpty ? join.childTable : join.childTableAlias).\(col.name)"
                            joinedRecord[id] = ""
                        }
                        
                        // Save match
                        records.append(joinedRecord)
                    }
                }
            } else {
                // Accumulate records from parent table
                for parentRecord in parentTable.rows {
                    // Build new record
                    var record: ADRecord = [:]
                    
                    // Accumulate parent columns
                    for (key, col) in parentRecord {
                        let id = "\(join.parentTableAlias.isEmpty ? join.parentTable : join.parentTableAlias).\(key)"
                        record[id] = col
                    }
                    
                    // Has matching child records?
                    let childRecords = childTable.findRows(matching: parentRecord, onColumns: join.columnList)
                    if childRecords.count > 0 {
                        for childRecord in childRecords {
                            var joinedRecord = record
                            
                            // Include child columns
                            for (key, col) in childRecord {
                                let id = "\(join.childTableAlias.isEmpty ? join.childTable : join.childTableAlias).\(key)"
                                joinedRecord[id] = col
                            }
                            
                            // Save match
                            records.append(joinedRecord)
                        }
                    } else {
                        var joinedRecord = record
                        
                        // Pad record with empty child columns
                        for col in childTable.schema.column {
                            let id = "\(join.childTableAlias.isEmpty ? join.childTable : join.childTableAlias).\(col.name)"
                            joinedRecord[id] = ""
                        }
                        
                        // Save match
                        records.append(joinedRecord)
                    }
                }
            }
        case .cross:
            // Accumulate parent table rows
            for parentRecord in parentTable.rows {
                // Add child table columns
                for childRecord in childTable.rows {
                    var record: ADRecord = [:]
                    
                    // Accumulate parent columns
                    for (key, col) in parentRecord {
                        let id = "\(join.parentTableAlias.isEmpty ? join.parentTable : join.parentTableAlias).\(key)"
                        record[id] = col
                    }
                    
                    for (key, col) in childRecord {
                        let id = "\(join.childTableAlias.isEmpty ? join.childTable : join.childTableAlias).\(key)"
                        record[id] = col
                    }
                    
                    // Add to record set
                    records.append(record)
                }
            }
        default:
            break
        }
        
        // Has sub join?
        if let subJoin = join.childJoin {
            // Yes, compute that join too
            records = try accumulateJoinedRecords(fromJoin: subJoin, into: records)
        }
        
        // Return results
        return records
    }
    
    /**
     Continues pulling together all of the data represented by the joining of one or more tables. If a join is not taking place, the data from the parent table only is returned.
     - Parameters:
         - join: A `ADSQLJoinClause` defining the join.
         - records: The set of records that have currently been joined.
     - Returns: A `ADRecordSet` representing all of the data in the join.
     */
    private func accumulateJoinedRecords(fromJoin join: ADSQLJoinClause, into records: ADRecordSet) throws -> ADRecordSet {
        var processAs = ADSQLJoinClause.JoinType.none
        
        // Take action based on the join type
        switch join.type {
        case .natural:
            // Find all intersecting column names
            join.columnList = []
            let parentTable = tables[join.parentTable]!
            let childTable = tables[join.childTable]!
            for parentColumn in parentTable.schema.column {
                if childTable.schema.hasColumn(named: parentColumn.name) {
                    // Found intersection, record
                    join.columnList.append(parentColumn.name)
                }
            }
            
            // Any matches found?
            if join.columnList.count > 0 {
                processAs = .inner
            } else {
                processAs = .cross
            }
        case.inner:
            // Has join criteria?
            if join.onExpression == nil && join.columnList.count == 0 {
                processAs = .cross
            } else {
                processAs = .inner
            }
        case .cross:
            processAs = .cross
        case .leftOuter:
            // Has join criteria?
            if join.onExpression == nil && join.columnList.count == 0 {
                processAs = .cross
            } else {
                processAs = .leftOuter
            }
        default:
            throw ADSQLExecutionError.syntaxError(message: "Malformed JOIN clause for table `\(join.parentTable)`.")
        }
        
        // Access the parts of the join
        var joinedRecords: ADRecordSet = []
        let childTable = tables[join.childTable]!
        
        // Handle based on the requested process
        switch processAs {
        case .inner:
            // Has on or using statement?
            if let onClause = join.onExpression {
                // Accumulate records from parent table
                for parentRecord in records {
                    // Has matching child records?
                    let childRecords = try childTable.findRows(matching: parentRecord, on: onClause, alias: join.childTableAlias)
                    for childRecord in childRecords {
                        // Build new record
                        var record = parentRecord
                        
                        // Include child columns
                        for (key, col) in childRecord {
                            let id = "\(join.childTableAlias.isEmpty ? join.childTable : join.childTableAlias).\(key)"
                            record[id] = col
                        }
                        
                        // Save match
                        joinedRecords.append(record)
                    }
                }
            } else {
                // Accumulate records from parent table
                for parentRecord in records {
                    // Has matching child records?
                    let childRecords = childTable.findRows(matching: stripPaths(from: parentRecord), onColumns: join.columnList)
                    for childRecord in childRecords {
                        // Build new record
                        var record = parentRecord
                        
                        // Include child columns
                        for (key, col) in childRecord {
                            let id = "\(join.childTableAlias.isEmpty ? join.childTable : join.childTableAlias).\(key)"
                            record[id] = col
                        }
                        
                        // Save match
                        joinedRecords.append(record)
                    }
                }
            }
        case .leftOuter:
            // Has on or using statement?
            if let onClause = join.onExpression {
                // Accumulate records from parent table
                for parentRecord in records {
                    // Has matching child records?
                    let childRecords = try childTable.findRows(matching: parentRecord, on: onClause, alias: join.childTableAlias)
                    if childRecords.count > 0 {
                        for childRecord in childRecords {
                            // Build new record
                            var record = parentRecord
                            
                            // Include child columns
                            for (key, col) in childRecord {
                                let id = "\(join.childTableAlias.isEmpty ? join.childTable : join.childTableAlias).\(key)"
                                record[id] = col
                            }
                            
                            // Save match
                            joinedRecords.append(record)
                        }
                    } else {
                        // Build new record
                        var record = parentRecord
                        
                        // Pad record with empty child columns
                        for col in childTable.schema.column {
                            let id = "\(join.childTableAlias.isEmpty ? join.childTable : join.childTableAlias).\(col.name)"
                            record[id] = ""
                        }
                        
                        // Save match
                        joinedRecords.append(record)
                    }
                }
            } else {
                // Accumulate records from parent table
                for parentRecord in records {
                    // Has matching child records?
                    let childRecords = childTable.findRows(matching: stripPaths(from: parentRecord), onColumns: join.columnList)
                    if childRecords.count > 0 {
                        for childRecord in childRecords {
                            // Build new record
                            var record = parentRecord
                            
                            // Include child columns
                            for (key, col) in childRecord {
                                let id = "\(join.childTableAlias.isEmpty ? join.childTable : join.childTableAlias).\(key)"
                                record[id] = col
                            }
                            
                            // Save match
                            joinedRecords.append(record)
                        }
                    } else {
                        // Build new record
                        var record = parentRecord
                        
                        // Pad record with empty child columns
                        for col in childTable.schema.column {
                            let id = "\(join.childTableAlias.isEmpty ? join.childTable : join.childTableAlias).\(col.name)"
                            record[id] = ""
                        }
                        
                        // Save match
                        joinedRecords.append(record)
                    }
                }
            }
        case .cross:
            // Combine with all records from the source table
            for record in records {
                // Add child table columns
                for childRecord in childTable.rows {
                    var joinedRecord = record
                    
                    for (key, col) in childRecord {
                        let id = "\(join.childTableAlias.isEmpty ? join.childTable : join.childTableAlias).\(key)"
                        joinedRecord[id] = col
                    }
                    
                    // Accumulate
                    joinedRecords.append(joinedRecord)
                }
            }
        default:
            break
        }
        
        // Has sub join?
        if let subJoin = join.childJoin {
            // Yes, compute that join too
            joinedRecords = try accumulateJoinedRecords(fromJoin: subJoin, into: joinedRecords)
        }
        
        // Return results
        return joinedRecords
    }

    /**
     Encodes the data store into an Instance Dictionary for storage in a Swift Portable Object Notation (SPON) format.
     -Returns: The data store represented as an Instance Dictionary.
     */
    public func encode() -> ADInstanceDictionary {
        let dictionary = ADInstanceDictionary()
        
        // Build array
        let array = ADInstanceArray()
        for table in tables.values {
            array.storage.append(table.encode())
        }
        
        // Save values
        dictionary.typeName = "DataStore"
        dictionary.storage["tableLastInsertedInto"] = tableLastInsertedInto
        dictionary.storage["tableRowsLastModified"] = tableRowsLastModified
        dictionary.storage["tables"] = array
        
        return dictionary
    }
    
    /**
     Decodes the data store from an Instance Dictionary that has been read from a Swift Portable Object Notation (SPON) stream.
     - Parameter dictionary: A `ADInstanceDictionary` representing the values for the data store.
     */
    public func decode(fromInstance dictionary: ADInstanceDictionary) {
        tableLastInsertedInto = dictionary.storage["tableLastInsertedInto"] as! String
        tableRowsLastModified = dictionary.storage["tableRowsLastModified"] as! Int
        if let array = dictionary.storage["tables"] as? ADInstanceArray {
            for item in array.storage {
                if let value = item as? ADInstanceDictionary {
                    let table = ADTableStore(fromInstance: value)
                    tables[table.schema.name] = table
                }
            }
        }
    }
}
