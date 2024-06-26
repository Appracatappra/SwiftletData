//
//  ADSPONProvider.swift
//  ActionControls
//
//  Created by Kevin Mullins on 11/22/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation
import SwiftletUtilities

/**
 The `ADSPONProvider` provides both light-weight, low-level access to data stored in a Swift Portable Object Notation (SPON) database and high-level access via a Object Relationship Management (ORM) model. Use provided functions to read and write data stored in a `ADRecord` format from and to the database using SQL statements directly.
 
 ## Example:
 ```swift
 let provider = ADSPONProvider.shared
 let record = try provider.query("SELECT * FROM Categories WHERE id = ?", withParameters: [1])
 print(record["name"])
 ```
 
 Optionally, pass a class instance conforming to the `ADDataTable` protocol to the `ADSPONProvider` and it will automatically handle reading, writing and deleting data as required.
 
 ## Example:
 ```swift
 let addr1 = Address(addr1: "PO Box 1234", addr2: "", city: "Houston", state: "TX", zip: "77012")
 let addr2 = Address(addr1: "25 Nasa Rd 1", addr2: "Apt #123", city: "Seabrook", state: "TX", zip: "77586")
 
 let p1 = Person(firstName: "John", lastName: "Doe", addresses: ["home":addr1, "work":addr2])
 let p2 = Person(firstName: "Sue", lastName: "Smith", addresses: ["home":addr1, "work":addr2])
 
 let group = Group(name: "Employees", people: [p1, p2])
 try provider.save(group)
 ```
 - Remark: The `ADSPONProvider` will automatically create a SQL Table from a class instance if one does not already exist. In addition, `ADSPONProvider` contains routines to preregister or update the schema classes conforming to the `ADDataTable` protocol which will build or modify the database tables as required.
 */
open class ADSPONProvider: ADDataProvider {
    
    // MARK: - Static Properties
    /// Provides access to a common, shared instance of the `ADSPONProvider`. For app's that are working with a single SPON database, they can use this instance instead of creating their own instance of a `ADSPONProvider`.
    public static let shared = ADSPONProvider()
    
    // MARK: - Private Properties
    /// Internal name for GCD queue used to execute SQL commands so that all commands are executed sequentially.
    private let queueLabel = "SPONdb"
    
    /// The internal Centeral Dispatch Queue used to run database commands.
    private var queue: DispatchQueue!
    
    /// Internal handle to the currently open SQLite DB instance.
    private var dataStore = ADDataStore()
    
    /// Internal DateFormatter instance used to manage date formatting.
    private let dateFormatter = DateFormatter()
    
    /// Internal encoder for database records.
    private let encoder = ADSQLEncoder()
    
    /// Internal decoder for database records.
    private let decoder = ADSQLDecoder()
    
    // MARK: - Public Properties
    /// Reference to the currently open database path or "" if no database is currently open.
    public private(set) var path: String = ""
    
    /// The name of the currently open SPON database or "" if no database is currently open.
    public private(set) var databaseName = ""
    
    /// Gets the current user-defined version number for the database. This value can be useful in managing data migrations so that you can add new columns to your tables or massage your existing data to suit a new situation.
    public var databaseVersion: Int {
        get {
            var version = 0
            if let arr = try? query("PRAGMA user_version") {
                if arr.count == 1 {
                    version = arr[0]["user_version"] as! Int
                }
            }
            return version
        }
    }
    
    /// Returns `true` if a SPON data source is open in-memory, else returns `false`.
    public var isOpen: Bool {
        return (!databaseName.isEmpty)
    }
    
    /// Returns `true` if the data provider can write to the currently open SPON database, else returns `false`.
    public private(set) var isReadOnly: Bool = false
    
    /// An array of all tables that have been read from or written to the given data source.
    public var knownTables: [String] = []
    
    // MARK: - Initializers
    /// Initializes a new instance of a `ADSQLiteProvider`.
    public init() {
        
        // Set up essentials
        queue = DispatchQueue(label:queueLabel, attributes:[])
        
        // You need to set the locale in order for the 24-hour date format to work correctly on devices where 24-hour format is turned off
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    }
    
    // MARK: - Deinitializers
    /// Deinitializes an instance of a `ADSPONProvider`.
    deinit {
        // Close any open databases
        do {
            try closeSource()
        } catch {
            // Ignore error for now.
        }
    }
    
    // MARK: - Public Functions
    /**
     Removes the given table from the list of known table names.
     
     ## Example:
     ```swift
     ADSQLiteProvider.shared.forgetTable("Category)
     ```
     
     - Parameter name: The name of the table to forget.
     */
    public func forgetTable(_ name: String) {
        if let index = knownTables.firstIndex(of: name) {
            knownTables.remove(at: index)
        }
    }
    
    /**
     Opens the given SPON database file for the data provider from either the app's Document or Bundle directories. If opening a database from the Document directory and it does not exist, the database will automatically be created. If opening a database from the Bundle directory for write access, the database will first be copied to the Document directory (if a copy doesn't already exist there), and the Document directory copy of the database will be opened.
     
     ## Example:
     ```swift
     try ADSPONProvider.shared.openSource("MyData.spon")
     ```
     
     - Parameters:
         - fileName: The name of the SPON database file to open.
         - fromBundle: If `true`, open the file from the app's Bundle.
         - readOnly: If `true` the data provider cannot write to the database.
     */
    public func openSource(_ fileName: String, fromBundle: Bool = false, readOnly: Bool = false) throws {
        
        // Close any open databases
        if isOpen {
            try closeSource()
        }
        
        // Prepare for file operations
        let fm = FileManager.default
        
        // If macOS, add app name to path since otherwise, DB could possibly interfere with another app using SQLiteDB
        #if os(macOS)
            // Get path to the Documents directory
            var docDir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
            
            let info = Bundle.main.infoDictionary!
            let appName = info["CFBundleName"] as! String
            docDir = (docDir as NSString).appendingPathComponent(appName)
            // Create folder if it does not exist
            if !fm.fileExists(atPath:docDir) {
                do {
                    try fm.createDirectory(atPath:docDir, withIntermediateDirectories:true, attributes:nil)
                } catch {
                    assert(false, "ADSPONProvider: Error creating DB directory: \(docDir) on macOS")
                    return
                }
            }
        #else
            // Get path to the Documents directory
            let docDir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
        #endif
        
        // Default path to the Document directory
        path = (docDir as NSString).appendingPathComponent(fileName)
        
        // Opening from the app's bundle?
        if fromBundle {
            // Gain access to the resource directory
            guard let rp = Bundle.main.resourcePath else {
                throw ADDataProviderError.dataSourceNotFound
            }
            
            // Read only access?
            if readOnly {
                // Yes, set the path to the
                path = (rp as NSString).appendingPathComponent(fileName)
                
                // Does the file exist?
                if !fm.fileExists(atPath: path) {
                    // No, report failure
                    throw ADDataProviderError.dataSourceNotFound
                }
            } else if !fm.fileExists(atPath: path) {
                // Copy database from Bundle to the Document directory
                let from = (rp as NSString).appendingPathComponent(fileName)
                do {
                    try fm.copyItem(atPath:from, toPath:path)
                } catch let error {
                    let msg = "\(error.localizedDescription)"
                    throw ADDataProviderError.dataSourceCopyFailed(message: msg)
                }
            }
        }
        
        // Has the data source been created yet?
        if fm.fileExists(atPath: path) {
            // Yes, open the database
            let url = URL(fileURLWithPath: path)
            let spon = try String(contentsOf: url, encoding: .utf8)
            dataStore = ADDataStore(fromSPON: spon)
        }
        
        // Save states
        databaseName = fileName
        isReadOnly = readOnly
    }
    
    /**
     Creates the given SPON database file for the data provider in the app's Document directory. If the database file already exists, it will be opened instead.
     
     ## Example:
     ```swift
     try ADSPONProvider.shared.createSource("MyData.spon")
     ```
     
     - Parameter fileName: The name of the SPON database file to create.
     - Remark: Passing an empty string ("") for the filename will create an in-memory only database without attempting to create a persisted disk file. You will need to call the `saveSource` method (instead of the `persist` method) to save a database created this way to disk.
     */
    public func createSource(_ filename: String) throws {
        
        // Close any open databases
        if isOpen {
            try closeSource()
        }
        
        // In-memory only?
        if filename.isEmpty {
            // The database is NOT persisted to disk file
            path = ""
        } else {
            // Prepare for file operations
            let fm = FileManager.default
            
            // If macOS, add app name to path since otherwise, DB could possibly interfere with another app using SQLiteDB
            #if os(macOS)
                // Get path to the Documents directory
                var docDir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
                
                let info = Bundle.main.infoDictionary!
                let appName = info["CFBundleName"] as! String
                docDir = (docDir as NSString).appendingPathComponent(appName)
                // Create folder if it does not exist
                if !fm.fileExists(atPath:docDir) {
                    do {
                        try fm.createDirectory(atPath:docDir, withIntermediateDirectories:true, attributes:nil)
                    } catch {
                        assert(false, "ADSPONProvider: Error creating DB directory: \(docDir) on macOS")
                        return
                    }
                }
            #else
                // Get path to the Documents directory
                let docDir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
            #endif
            
            // Default path to the Document directory
            path = (docDir as NSString).appendingPathComponent(filename)
            
            // Has the data source been created yet?
            if fm.fileExists(atPath: path) {
                // Yes, open the database
                let url = URL(fileURLWithPath: path)
                let spon = try String(contentsOf: url, encoding: .utf8)
                dataStore = ADDataStore(fromSPON: spon)
            }
        }
        
        // Save states
        databaseName = (filename.isEmpty) ? "untitled" : filename
        isReadOnly = false
    }
    
    /**
     Saves the SPON database to the given filename.
     
     ## Example:
     ```swift
     try ADSPONProvider.shared.saveSource("MyData.spon")
     ```
     
     - Parameter fileName: The name of the file to save the SPON database to.
     - Remark: The `saveSource` method is typically used to save a SPON database created with the `createSource("")` method call. After calling `saveSource` the `persist` method can be called to save further database changes to disk.
    */
    public func saveSource(_ filename: String) throws {
        
        // Is the database open?
        if !isOpen {
            throw ADDataProviderError.dataSourceNotOpen
        }
        
        // Prepare for file operations
        let fm = FileManager.default
        
        // If macOS, add app name to path since otherwise, DB could possibly interfere with another app using SQLiteDB
        #if os(macOS)
            // Get path to the Documents directory
            var docDir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
            
            let info = Bundle.main.infoDictionary!
            let appName = info["CFBundleName"] as! String
            docDir = (docDir as NSString).appendingPathComponent(appName)
            // Create folder if it does not exist
            if !fm.fileExists(atPath:docDir) {
                do {
                    try fm.createDirectory(atPath:docDir, withIntermediateDirectories:true, attributes:nil)
                } catch {
                    assert(false, "ADSPONProvider: Error creating DB directory: \(docDir) on macOS")
                    return
                }
            }
        #else
            // Get path to the Documents directory
            let docDir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
        #endif
        
        // Default path to the Document directory
        path = (docDir as NSString).appendingPathComponent(filename)
        databaseName = filename
        isReadOnly = false
        
        // Save to disk
        try persist()
    }
    
    /**
     Attempts to persist the in-memory data store to disk if the database is open, not read only and was origionally opened from a persistant source.
     
     ## Example:
     ```swift
     ADSPONProvider.shared.persist()
     ```
    */
    public func persist() throws {
        // Is the database open, not read-only and read from disk?
        if isOpen && !isReadOnly && !path.isEmpty {
            // Yes, save contents to storage
            let url = URL(fileURLWithPath: path)
            let dictionary = dataStore.encode()
            let spon = dictionary.encode()
            try spon.write(to: url, atomically: true, encoding: String.Encoding.utf8)
        }
    }
    
    /**
     Attempts to persist and close the currently open SPON database.
     
     ## Example:
     ```swift
     ADSPONProvider.shared.closeSource()
     ```
     */
    public func closeSource() throws {
        
        // Attempt to persist before closing.
        try persist()
        
        // Reset provider
        databaseName = ""
        knownTables = []
        dataStore = ADDataStore()
        path = ""
    }
    
    /**
     For writable databases stored in the app's document directory, delete the data source with the specified file name.
     
     ## Example:
     ```swift
     ADSPONProvider.deleteSource("MyDatabase.spon")
     ```
     
     - Parameter fileName: The name of the SPON database to delete.
     - Warning: This command will totally erase the database from the device's storage and is not undoable!
     */
    public func deleteSource(_ fileName: String) throws {
        // Close any open databases
        if isOpen {
            try closeSource()
        }
        
        // Prepare for file operations
        let fm = FileManager.default
        
        // Get path to the Documents directory
        let docDir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
        
        // Default path to the Document directory
        path = (docDir as NSString).appendingPathComponent(fileName)
        
        do {
            try fm.removeItem(atPath: path)
        } catch {
            // Deletion failed
            throw ADDataProviderError.failedToDeleteSource
        }
    }
    
    /// Returns an ISO-8601 date string for a given date.
    ///
    /// - Parameter fromDate: The date to format in to an ISO-8601 string
    /// - Returns: A string with the date in ISO-8601 format.
    func makeSQLDate(fromDate:Date) -> String {
        return dateFormatter.string(from:fromDate)
    }
    
    /**
     Execute SQL (non-query) command with (optional) parameters and return result code.
     
     ## Example:
     ```swift
     let sql = "CREATE TABLE IF NOT EXISTS Person (`ID` INTEGER, `Name` STRING)"
     try ADSPONProvider.shared.execute(sql)
     ```
     
     - Parameters:
         - sql: The SQL statement to be executed.
         - parameters: An array of optional parameters incase the SQL statement includes bound parameters (indicated by `?` in the SQL Statement).
     - Returns: If executing an `INSERT` command of a record with an `INTEGER` id, the last inserted ID will be returned. For `DELETE` and `UPDATE` commands, a count of number of records modified will be returned. All other commands will return `1` on success and `-1` on failure.
     */
    @discardableResult public func execute(_ sql: String, withParameters parameters: [Any]? = nil) throws -> Int {
        
        // Ensure that the database is open
        if !isOpen {
            throw ADDataProviderError.dataSourceNotOpen
        }
        
        // Execute the SQL against the data store
        try queue.sync {
            if let params = parameters {
                try dataStore.execute(sql, parameters: params)
            } else {
                try dataStore.execute(sql)
            }
        }
        
        // Report the results of the statement
        let upp = sql.uppercased()
        var result = -1
        if upp.hasPrefix("INSERT ") {
            result = dataStore.lastInsertedRowID
        } else if upp.hasPrefix("DELETE") || upp.hasPrefix("UPDATE") {
            result = dataStore.numberOfRecordsChanged
        } else {
            result = 1
        }
        
        return result
    }
    
    /**
     Run an SQL query with (parameters) parameters and returns an array of dictionaries where the keys are the column names.
     
     ## Example:
     ```swift
     let sql = "SELECT * FROM Person WHERE ID = ?"
     let records = try ADSPONProvider.shared.query(sql, withParameters: [1])
     ```
     
     - Parameters:
         - sql: The SQL statement to be executed.
         - parameters: An array of optional parameters incase the SQL statement includes bound parameters (indicated by `?` in the SQL Statement).
     - Returns: An empty array if the query resulted in no rows. Otherwise, an array of dictionaries where each dictioanry key is a column name and the value is the column value as a `ADRecordSet`.
     */
    public func query(_ sql: String, withParameters parameters: [Any]? = nil) throws -> ADRecordSet {
        var rows = ADRecordSet()
        
        // Ensure that the database is open
        if !isOpen {
            throw ADDataProviderError.dataSourceNotOpen
        }
        
        // Execute the query
        try queue.sync {
            if let params = parameters {
                rows = try dataStore.query(sql, parameters: params)
            } else {
                rows = try dataStore.query(sql)
            }
        }
        
        // Return results
        return rows
    }
    
    /**
     Checks to see if the given table exists in the SPON database.
     
     ## Example:
     ```swift
     let exists = try ADSPONProvider.shared.tableExists("Person)
     ```
     
     - Parameter tableName: The name the table to check.
     - Returns: `true` if the table exists, else `false`.
     */
    public func tableExists(_ tableName: String) throws -> Bool {
        // Query data store for table.
        return dataStore.hasTable(named: tableName)
    }
    
    /**
     Counts the number of records in a given SPON database table, optionally filtered by a given set of contraints.
     
     ## Example:
     ```swift
     let count = try ADSPONProvider.shared.countRows(inTable: "Person", filteredBy: "ID = ?", withParameters: [1])
     ```
     
     - Parameters:
         - table: The name of the table to count records for.
         - filter: The optional filter criteria to be used in fetching the data. Specify the filter criteria in the form of a valid SQLite WHERE clause (without the actual `WHERE` keyword). If this parameter is omitted or a blank string is provided, all rows will be fetched.
         - parameters: An array of optional parameters incase the SQL statement includes bound parameters (indicated by `?` in the SQL Statement).
     - Returns: An integer value indicating the total number of rows, if no filter criteria was provided, or the number of rows matching the provided filter criteria. If the table doesn't exist, 0 is returned.
     */
    public func countRows(inTable table: String, filteredBy filter: String = "", withParameters parameters: [Any]? = nil) throws -> Int {
        
        var sql = "SELECT COUNT(*) AS count FROM \(table)"
        if !filter.isEmpty {
            sql += " WHERE \(filter)"
        }
        let arr = try query(sql, withParameters: parameters)
        if arr.count == 0 {
            return 0
        }
        if let val = arr[0]["count"] as? Int {
            return val
        }
        return 0
    }
    
    /**
     Gets the largest used number for the given integer primary key of the given table.
     
     ## Example:
     ```swift
     let lastID = try ADSPONProvider.shared.lastIntID(forTable: "Person", withKey: "ID")
     ```
     
     - Remark: This function works with integer primary keys that are not marked AUTOINCREMENT and is useful when the data being stored in a database needs to know the next available ID before a record has been saved.
     
     - Parameters:
         - table: The name of the table to get the last ID from.
         - primaryKey: The name of the primary key.
     - Returns: The largest used number for the given primary key or zero if no record has been written to the table yet.
     */
    public func lastIntID(forTable table: String, withKey primaryKey: String) throws -> Int {
        
        let sql = "SELECT MAX(\(primaryKey)) AS lastID FROM \(table) LIMIT 1"
        let arr = try query(sql)
        if arr.count == 0 {
            return 0
        }
        if let val = arr[0]["lastID"] as? Int {
            return val
        }
        return 0
    }
    
    /**
     Gets the last auto generated integer ID for the given table.
     
     ## Example:
     ```swift
     let lastID = ADSPONProvider.shared.lastAutoID(forTable: "Category")
     ```
     
     - Remark: This function works with AUTOINCREMENT primary key types and returns the last ID generated after data has been saved to the database.
     
     - Parameters:
        - table: The name of the table to get the last ID from.
     - Returns: The last auto generated integer id or zero if no data has been saved to the table or if the table does not have an auto generated integer primary key.
     */
    public func lastAutoID(forTable table: String) throws -> Int {
        
        // Ensure data store contains requested table.
        if dataStore.hasTable(named: table) {
            let tbl = dataStore.tables[table]!
            if let value = tbl.lastPrimaryKeyValue as? Int {
                return value
            }
        }
        
        // Not valid, return 0
        return 0
    }
    
    /**
     Returns all information about a given table in the SPON database including all of the columns and their types.
     
     ## Example:
     ```swift
     let schema = try ADSPONProvider.shared.getTableSchema(forTableName: "Category")
     ```
     
     - Parameter name: The name of the table to return the schema for.
     - Returns: A `ADTableSchema` instance describing the requested table.
     */
    public func getTableSchema(forTableName name: String) throws -> ADTableSchema {
        
        // Does the data store have the requested table?
        if dataStore.hasTable(named: name) {
            let table = dataStore.tables[name]!
            return table.schema
        } else {
            throw ADDataProviderError.tableNotFound(message: "Table \(name) is not in the database.")
        }
        
    }
    
    /// Starts an explicit transaction to process a batch of database changes. Once started, the transaction will remain open until it is either committed (via `endTransaction`) or rolled-back (via `rollbackTransaction`).
    public func beginTransaction() throws {
        let sql = "BEGIN TRANSACTION;"
        try execute(sql)
    }
    
    /// Attempts to commit any chages to the database and close the current transaction that was opened using `beginTransaction`.
    public func endTransaction() throws {
        let sql = "COMMIT TRANSACTION;"
        try execute(sql)
    }
    
    /// Ends the current transaction (opened using `beginTransaction`) and undoes any changes made to the database since the transaction was opened.
    public func rollbackTransaction() throws {
        let sql = "ROLLBACK TRANSACTION;"
        try execute(sql)
    }
    
    // MARK: - ORM Functions
    /**
     Registers the given `ADDataTable` class schema with the data provider and creates a table for the class if it doesn't already exist.
     
     ## Example:
     ```swift
     try ADSPONProvider.shared.registerTableSchema(Category.self)
     ```
     
     - Remark: Classes are usually registered when an app first starts, directly after a database is opened.
     - Parameters:
        - type: The type of the class to register.
     - instance: An instance of the type with all properties set to the default values that you want to have added to the data source.
     */
    public func registerTableSchema<T: ADDataTable>(_ type: T.Type, withDefaultValues instance: T = T.init()) throws {
        
        // Build a new instance of the record and encode it
        let record = try encoder.encode(instance) as! ADRecord
        
        // Build table if required
        try ensureTableExists(type: type, rowData: record)
    }
    
    /**
     Attempts to modify the SPON database table schema to match the schema of the given `ADDataTable` class if the schema has changed. If the table does not exist, it will attempt to be registered with the database. If any new columns have been added, the default values will be set from the given defaults.
     
     ## Example:
     ```swift
     try ADSPONProvider.shared.updateTableSchema(Category.self)
     ```
     
     - Parameters:
        - type: The type of the class to update the schema of.
        - instance: An instance of the type with all properties set to the default values that you want to have added to the database.
     */
    public func updateTableSchema<T: ADDataTable>(_ type: T.Type, withDefaultValues instance: T = T.init()) throws {
        
        // Is this a known table
        if try !tableExists(type.tableName) {
            // Try to register and return
            try registerTableSchema(type)
            return
        }
        
        // Build a new instance of the record and encode it
        let record = try encoder.encode(instance) as! ADRecord
        
        // Get the current table schema
        let schema = try getTableSchema(forTableName: type.tableName)
        
        // Do the schemas still match?
        var schemasMatch = true
        for key in record.keys {
            if !schema.hasColumn(named: key) {
                // The schemas have changed
                schemasMatch = false
                break
            }
        }
        
        // Is an update needed?
        if schemasMatch {
            // No, stop processing and register table if needed
            if !knownTables.contains(type.tableName) {
                // Add to know tables
                knownTables.append(type.tableName)
            }
            return
        }
        
        // Disable foreign keys and start a transaction
        var sql = "BEGIN TRANSACTION;"
        try execute(sql)
        
        // Trap any datbase errors and rollback if issue
        do {
            // Rename existing table
            let tempTableName = "temp_\(type.tableName)"
            sql = "ALTER TABLE \(type.tableName) RENAME TO \(tempTableName);"
            try execute(sql)
            
            // Create the new table
            sql = "CREATE TABLE IF NOT EXISTS \(type.tableName) (\(try getColumnSQL(type: type, columns: record)));"
            let rc = try execute(sql)
            if rc < 0 {
                throw ADDataProviderError.failedToCreateTable(message: "Table: \(type.tableName) with SQL: \(sql)")
            }
            
            // Move existing data to the new table
            var columns = ""
            for col in schema.column {
                // Ensure the column exists in the new table
                if record.keys.contains(col.name) {
                    if columns.isEmpty {
                        columns = col.name
                    } else {
                        columns += ", \(col.name)"
                    }
                }
            }
            if !columns.isEmpty {
                sql = "INSERT INTO \(type.tableName) (\(columns)) SELECT \(columns) FROM \(tempTableName);"
                try execute(sql)
            }
            
            // Add default values for any new column
            columns = ""
            var parameters: [Any] = []
            for (name, value) in record {
                // Is this a new column?
                if !schema.hasColumn(named: name) {
                    // No, we need to configure this column in the new table
                    if !columns.isEmpty {
                        columns += ", "
                    }
                    columns += "\(name) = ?"
                    parameters.append(value)
                }
            }
            if !columns.isEmpty {
                sql = "UPDATE \(type.tableName) SET \(columns)"
                try execute(sql, withParameters: parameters)
            }
            
            // Re-enable foreign keys and end transaction
            sql = "DROP TABLE \(tempTableName); COMMIT;"
            try execute(sql)
            
            // Register type with database
            if !knownTables.contains(type.tableName) {
                // Add to know tables
                knownTables.append(type.tableName)
            }
        } catch {
            sql = "ROLLBACK TRANSACTION;"
            try execute(sql)
            throw ADDataProviderError.failedToUpdateTableSchema(message: "ERROR: \(error)")
        }
    }
    
    /**
     Checks to see if a row matching the given primary key exists in the underlying SPON table.
     
     ## Example:
     ```swift
     let found = try ADSPONProvider.shared.hasRow(forType: Person.self, matchingPrimaryKey: 1)
     ```
     
     - Parameters:
         - type: The `ADDataTable` class to check if the row exists for.
         - key: The primary key value to search for.
     - Returns: `true` if a row matching the primary key is found, else `false`.
     */
    public func hasRow<T: ADDataTable>(forType type: T.Type, matchingPrimaryKey key: Any) throws -> Bool {
        let sql = "SELECT COUNT(*) AS count FROM \(type.tableName) WHERE \(type.primaryKey) = ?"
        let records = try query(sql, withParameters: [key])
        
        if records.count > 0 {
            if let count = records[0]["count"] as? Int {
                return (count > 0)
            }
        }
        
        // Not found
        return false
    }
    
    /**
     Return the count of rows in the table, or the count of rows matching a specific filter criteria, if one was provided.
     
     ## Example:
     ```swift
     let count = try ADSPONProvider.shared.rowCount(forType: Person.self)
     ```
     
     - Parameters:
         - type: A class conforming to the `ADDataTable` protocol to count rows for.
         - filter: The optional filter criteria to be used in fetching the data. Specify the filter criteria in the form of a valid SQLite `WHERE` clause (without the actual `WHERE` keyword). If this parameter is omitted or a blank string is provided, all rows will be fetched.
         - parameters: An array of optional parameters incase the SQL statement includes bound parameters (indicated by `?` in the SQL Statement).
     - Returns: An integer value indicating the total number of rows or rows matching the optional filter in the given table.
     */
    public func rowCount<T: ADDataTable>(forType type: T.Type, filterBy filter: String = "", withParameters parameters: [Any]? = nil) throws -> Int {
        return try countRows(inTable: type.tableName, filteredBy: filter, withParameters: parameters)
    }
    
    /**
     Creates an instance of the given `ADDataTable` class automatically setting the **primaryKey** field based on the value of the **primaryKeyType**.
     
     ## Example:
     ```swift
     var category = try ADSPONProvider.shared.make(Category.self)
     ```
     
     - Parameter type: The class conforming to the `ADDataTable` protocol to create an instance of.
     - Returns: A new instance of the given class with the **primaryKey** automatically set.
     */
    public func make <T: ADDataTable>(_ type: T.Type) throws -> T {
        
        // Build a new instance of the record and encode it
        let instance = type.init()
        var record = try encoder.encode(instance) as! ADRecord
        
        // Take action based on the primary key type
        switch type.primaryKeyType {
        case .autoUUIDString:
            let id = UUID().uuidString
            record[type.primaryKey] = id
        case .autoIncrementingInt:
            let id = -1
            record[type.primaryKey] = id
        case .computedInt:
            let id = try lastIntID(forTable: type.tableName, withKey: type.primaryKey) + 1
            record[type.primaryKey] = id
        default:
            break
        }
        
        // Convert back into a class and return
        return try decoder.decode(type, from: record)
    }
    
    /**
     Returns a value for the **primaryKey** field based on the value of the **primaryKeyType** for a class conforming to the `ADDataTable` protocol.
     
     ## Example:
     ```swift
     let id = ADSPONProvider.shared.makeID(Category.self) as! Int
     ```
     
     - Parameter type: The class conforming to the `ADDataTable` protocol to create primary key for.
     - Returns: A new primary key value if it can be generated, else returns `nil`.
     */
    public func makeID<T: ADDataTable>(_ type: T.Type) -> Any? {
        
        // Take action based on the primary key type
        switch type.primaryKeyType {
        case .autoUUIDString:
            return UUID().uuidString
        case .autoIncrementingInt:
            return -1
        case .computedInt:
            if let id = try? lastIntID(forTable: type.tableName, withKey: type.primaryKey) {
                return id + 1
            } else {
                return 1
            }
        default:
            return nil
        }
    }
    
    /**
     Saves the given class conforming to the `ADDataTable` protocol to the database. If the SPON database does not contain a table named in the **tableName** property, one will be created first. If a record is not on file matching the **primaryKey** value, a new record will be created, else the existing record will be updated.
     
     ## Example:
     ```swift
     var category = Category()
     try ADSPONProvider.shared.save(category)
     ```
     
     - Parameter value: The class instance to save to the database.
     - Returns: If inserting a record with an `INTEGER` id, the last inserted ID will be returned, else the primary key value will be returned.
     */
    @discardableResult public func save<T: ADDataTable>(_ value: T) throws -> Any {
        let baseType = type(of: value)
        var insert = true
        
        // Try to encode record
        var data = try encoder.encode(value) as! ADRecord
        
        // Ensure the table has been created
        try ensureTableExists(type: baseType, rowData: data)
        
        // Is a key already defined
        if let key = data[baseType.primaryKey] {
            // Yes, check to see if we are updating or inserting
            insert = try !hasRow(forType: baseType, matchingPrimaryKey: key)
        }
        
        // Check for sub table references and save them first
        for (key, val) in data {
            // Linking to a foreign table?
            if let box = val as? ADInstanceDictionary {
                // Save subtable first and record its key
                data[key] = try save(box)
            } else if let xref = val as? ADDataCrossReference {
                let key = data[baseType.primaryKey]!
                try xref.save(to: self, forKeyValue: key)
            }
        }
        
        // Perform insert or update
        let (sql, params) = getSQL(type: baseType, data: data, forInsert: insert)
        let rc = try execute(sql, withParameters: params)
        
        // If successful attempt to update key
        if insert && rc > -1 {
            switch(baseType.primaryKeyType) {
            case .autoIncrementingInt:
                return try lastAutoID(forTable: baseType.tableName)
            case .computedInt:
                return try lastIntID(forTable: baseType.tableName, withKey: baseType.primaryKey)
            default:
                return data[baseType.primaryKey]!
            }
        }
        
        // Return results
        return rc
    }
    
    /**
     Checks to see if the Swift object incoded in the give box has already been saved to the database.
     
     - Parameter box: A `ADInstanceDictionary` holding an encoded Swift object.
     - Returns: `true` if the object is already in the database else returns false.
     */
    private func hasRecord(_ box: ADInstanceDictionary) throws -> Bool {
        let sql = "SELECT COUNT(\(box.subTablePrimaryKey)) AS num FROM \(box.subTableName) WHERE \(box.subTablePrimaryKey) = ?"
        let key = box.storage[box.subTablePrimaryKey]!
        let arr = try query(sql, withParameters: [key])
        if arr.count == 0 {
            return false
        }
        if let val = arr[0]["num"] as? Int {
            return (val > 0)
        }
        return false
    }
    
    /**
     Saves the the Swift object encoded in a `ADInstanceDictionary` to the database. If the SPON database does not contain a table named in the **subtableName** property, one will be created first. If a record is not on file matching the **subTablePrimaryKey** value, a new record will be created, else the existing record will be updated.
     
     - Parameter data: A `ADInstanceDictionary` holding an encoded Swift object.
     - Returns: The primary key value for the saved record.
     */
    @discardableResult private func save(_ data: ADInstanceDictionary) throws -> Any {
        
        // Does table exist?
        try ensureTableExists(forBox: data)
        
        // Check for sub table references and save them first
        for (key, val) in data.storage {
            // Linking to a foreign table?
            if let box = val as? ADInstanceDictionary {
                // Save subtable first and record its key
                data.storage[key] = try save(box)
            } else if let xref = val as? ADDataCrossReference {
                let key = data.storage[data.subTablePrimaryKey]!
                try xref.save(to: self, forKeyValue: key)
            }
        }
        
        // Perform insert or update on sub table
        let (sql, params) = getSQL(forBox: data, forInsert: try !hasRecord(data))
        let fk = try execute(sql, withParameters: params)
        
        // Return resulting key
        if data.subTablePrimaryKeyType == .autoIncrementingInt || data.subTablePrimaryKeyType == .computedInt {
            return fk
        } else {
            return data.storage[data.subTablePrimaryKey]!
        }
    }
    
    /**
     Saves the given array of class instances conforming to the `ADDataTable` protocol to the database. If the SPON database does not contain a table named in the **tableName** property, one will be created first. If a record is not on file matching the **primaryKey** value, a new record will be created, else the existing record will be updated.
     
     ## Example:
     ```swift
     let c1 = Category()
     let c2 = Category()
     try ADSPONProvider.shared.save([c1, c2])
     ```
     
     - Parameter values: The array of class instances to save to the database.
     - Remark: Uses a transaction to process all database changes in a single batch. If an error occurs, all changes will be rolled-back and the database will not be modified.
     */
    public func save<T: ADDataTable>(_ values: [T]) throws {
        
        // Start transaction
        try beginTransaction()
        
        // Process all classes
        for value in values {
            do {
                try save(value)
            } catch {
                // Rollback the transaction and report error to caller
                try rollbackTransaction()
                throw ADDataProviderError.batchUpdateFailed(message: "Error: \(error)")
            }
        }
        
        // Commit changes to database
        try endTransaction()
    }
    
    /**
     Returns rows from the SPON database of the given class type optionally filtered, sorted and limited to a specific range of results.
     
     ## Example:
     ```swift
     let records = try ADSPONProvider.shared.getRows(ofType: Person.self)
     ```
     
     - Parameters:
         - type: A class conforming to the `ADDataTable` protocol to store the records in.
         - filter: The optional filter criteria to be used in fetching the data. Specify in the form of a valid SQL `WHERE` clause (without the actual `WHERE` keyword). If this parameter is omitted or a blank string is provided, all rows will be fetched.
         - order: The optional sorting criteria to be used in fetching the data. Specify in the form of a valid SQL `ORDER BY` clause (without the actual `ORDER BY` keyword). If this parameter is omitted or a blank string is provided, no sorting will be applied.
         - start: The starting index for the returned results. If omitted or zero, the result set starts with the first record.
         - limit: Limits the returned results to a maximum number. If omitted or zero, all matching results are returned.
         - parameters: An array of optional parameters incase the SQL statement includes bound parameters (indicated by `?` in the SQL Statement).
     - Returns: An array of matching records in the given class type or an empty array if no matching records were found.
     */
    public func getRows<T: ADDataTable>(ofType type: T.Type, fliteredBy filter: String = "", orderedBy order: String = "", startingAt start: Int = 0, limitedTo limit: Int = 0, withParameters parameters: [Any]? = nil) throws -> [T] {
        
        var sql = "SELECT * FROM \(type.tableName)"
        if !filter.isEmpty {
            sql += " WHERE \(filter)"
        }
        if !order.isEmpty {
            sql += " ORDER BY \(order)"
        }
        if limit > 0 {
            sql += " LIMIT \(start), \(limit)"
        }
        
        return try getRows(ofType: type, matchingSQL:sql, withParameters: parameters)
    }
    
    /**
     Returns rows from the SPON database of the given class type matching the given SQL statement.
     
     ## Example:
     ```swift
     let sql = "SELECT * FROM Person WHERE ID = ?"
     let records = try ADSPONProvider.shared.getRows(ofType: Person.self, matchingSQL: sql, withParameters: [1])
     ```
     
     - Parameters:
         - type: A class conforming to the `ADDataTable` protocol to store the records in.
         - sql: A valid SQL statement used to pull matching records from the database.
         - parameters: An array of optional parameters incase the SQL statement includes bound parameters (indicated by `?` in the SQL Statement).
     - Returns: An array of matching records in the given class type or an empty array if no matching records were found.
     */
    public func getRows<T: ADDataTable>(ofType type: T.Type, matchingSQL sql: String, withParameters parameters: [Any]? = nil) throws -> [T] {
        var results = [T]()
        let rows = try query(sql, withParameters: parameters)
        
        // Inspect type
        let obj = T()
        let schema = try encoder.encode(obj) as! ADRecord
        
        // Look for any subtables
        var subtable: [String:ADInstanceDictionary] = [:]
        var xrefs: [String:ADDataCrossReference] = [:]
        for (key, value) in schema {
            if let box = value as? ADInstanceDictionary {
                subtable[key] = box
            } else if let xref = value as? ADDataCrossReference {
                xrefs[key] = xref
            }
        }
        
        // Process all returned rows
        for var row in rows {
            // Process subtables
            for (key, box) in subtable {
                row[key] = try getRecord(withKey: row[key]!, forSchema: box)
            }
            
            // Process cross references
            let leftKey = row[type.primaryKey]!
            for (key, var xref) in xrefs {
                try xref.load(from: self, forKeyValue: leftKey)
                row[key] = xref
            }
            
            // Store record
            let record = try decoder.decode(type, from: row)
            results.append(record)
        }
        
        return results
    }
    
    /**
     Loads the record from a subtable for the given ID and Swift object type schema from the database.
     
     - Parameters:
         - id: The primary key value of the record to load.
         - schema: A `ADInstanceDictionary` holding an encoded Swift object type used as the prototype of the record to load.
     - Returns: A `ADRecord` matching the given ID and Swift object Schema.
     */
    private func getRecord(withKey id: Any, forSchema schema: ADInstanceDictionary) throws -> ADRecord {
        
        // Look for any subtables
        var subtable: [String:ADInstanceDictionary] = [:]
        var xrefs: [String:ADDataCrossReference] = [:]
        for (key, value) in schema.storage {
            if let box = value as? ADInstanceDictionary {
                subtable[key] = box
            } else if let xref = value as? ADDataCrossReference {
                xrefs[key] = xref
            }
        }
        
        // Get data
        let sql = "SELECT * FROM \(schema.subTableName) WHERE \(schema.subTablePrimaryKey) = ?"
        let rows = try query(sql, withParameters: [id])
        var row = rows[0]
        
        // Process subtables
        for (key, box) in subtable {
            row[key] = try getRecord(withKey: row[key]!, forSchema: box)
        }
        
        // Process cross references
        let leftKey = row[schema.subTablePrimaryKey]!
        for (key, var xref) in xrefs {
            try xref.load(from: self, forKeyValue: leftKey)
            row[key] = xref
        }
        
        // Return resulting row
        return row
    }
    
    /**
     Returns a row from the SPON database of the given class type matching the given primary key value.
     
     ## Example:
     ```swift
     let person = try ADSPONProvider.shared.getRow(ofType: Person.self, forPrimaryKeyValue: 1)
     ```
     
     - Parameters:
         - type: A class conforming to the `ADDataTable` protocol to store the records in.
         - key: The primary key value to return a record for.
     - Returns: A record of the requested type if found or `nil` if not found.
     */
    public func getRow<T: ADDataTable>(ofType type: T.Type, forPrimaryKeyValue key: Any) throws -> T? {
        let sql = "SELECT * FROM \(type.tableName) WHERE \(type.primaryKey) = ? LIMIT 1"
        let rows = try getRows(ofType: type, matchingSQL: sql, withParameters: [key])
        
        // Was anything returned
        if rows.count == 0 {
            return nil
        } else {
            return rows[0]
        }
    }
    
    /**
     Returns a row from the SPON database of the given class type optionally filtered and limited to a specific range of results.
     
     ## Example:
     ```swift
     let category = try ADSPONProvider.shared.getRow(ofType: Category.self, atIndex: 10)
     ```
     
     - Parameters:
         - type: A class conforming to the `ADDataTable` protocol to store the records in.
         - index: The starting index of the record to return.
         - filter: The optional filter criteria to be used in fetching the data. Specify in the form of a valid SQL `WHERE` clause (without the actual `WHERE` keyword). If this parameter is omitted or a blank string is provided, all rows will be fetched.
         - order: The optional sorting criteria to be used in fetching the data. Specify in the form of a valid SQL `ORDER BY` clause (without the actual `ORDER BY` keyword). If this parameter is omitted or a blank string is provided, no sorting will be applied.
         - parameters: An array of optional parameters incase the SQL statement includes bound parameters (indicated by `?` in the SQL Statement).
     - Returns: A record of the requested type if found or `nil` if not found.
     */
    public func getRow<T: ADDataTable>(ofType type: T.Type, atIndex index: Int, fliteredBy filter: String = "", orderedBy order: String = "", withParameters parameters: [Any]? = nil) throws -> T? {
        let rows = try getRows(ofType: type, fliteredBy: filter, orderedBy: order, startingAt: index, limitedTo: 1, withParameters: parameters)
        if rows.count == 0 {
            return nil
        } else {
            return rows[0]
        }
    }
    
    /**
     Deletes the row matching the given record from the SPON database.
     
     ## Example:
     ```swift
     let category = try ADSPONProvider.shared.getRow(ofType: Category.self, forPrimaryKeyValue: 10)
     try ADSPONProvider.shared.delete(category)
     ```
     
     - Parameter value: An instance of a class conforming to the `ADDataTable` protocol to delete from the database.
     */
    public func delete<T: ADDataTable>(_ value: T) throws {
        
        let data = try encoder.encode(value) as! ADRecord
        
        // Check for sub table references and delete them first
        for (_, val) in data {
            // Linking to a foreign table?
            if let box = val as? ADInstanceDictionary {
                // Delete subtable first
                try delete(box)
            } else if let xref = val as? ADDataCrossReference {
                let key = data[T.primaryKey]!
                try xref.delete(from: self, forKeyValue: key)
            }
        }
        
        if let key = data[T.primaryKey] {
            let sql = "DELETE FROM \(T.tableName) WHERE \(T.primaryKey) = ?"
            try execute(sql, withParameters: [key])
        }
    }
    
    /**
     Deletes the row from a subtable matching the given encoded Swift object.
     
     - Parameter box: A `ADInstanceDictionary` containing the object to delete.
     */
    private func delete(_ box: ADInstanceDictionary) throws {
        
        // Check for sub table references and delete them first
        for (_, val) in box.storage {
            // Linking to a foreign table?
            if let box = val as? ADInstanceDictionary {
                // Delete subtable first
                try delete(box)
            } else if let xref = val as? ADDataCrossReference {
                let key = box.storage[box.subTablePrimaryKey]!
                try xref.delete(from: self, forKeyValue: key)
            }
        }
        
        if let key = box.storage[box.subTablePrimaryKey] {
            let sql = "DELETE FROM \(box.subTableName) WHERE \(box.subTablePrimaryKey) = ?"
            try execute(sql, withParameters: [key])
        }
    }
    
    /**
     Deletes the given set of records from the database.
     
     ## Example:
     ```swift
     let c1 = try ADSPONProvider.shared.getRow(ofType: Category.self, forPrimaryKeyValue: 10)
     let c2 = try ADSPONProvider.shared.getRow(ofType: Category.self, forPrimaryKeyValue: 5)
     try ADSPONProvider.shared.delete([c1, c2])
     ```
     - Parameter values: An array of records to delete from the database.
     - Remark: Uses a transaction to process all data source changes in a single batch. If an error occurs, all changes will be rolled-back and the data source will not be modified.
     */
    public func delete<T: ADDataTable>(_ values: [T]) throws {
        
        // Start transaction
        try beginTransaction()
        
        // Process all classes
        for value in values {
            do {
                try delete(value)
            } catch {
                // Rollback the transaction and report error to caller
                try rollbackTransaction()
                throw ADDataProviderError.batchUpdateFailed(message: "Error: \(error)")
            }
        }
        
        // Commit changes to database
        try endTransaction()
    }
    
    /// Drops the underlying table from the SPON database, completely removing all stored data in the table as well as the table itself.
    /// - Parameter type: The type of table to drop.
    /// - Warning: This command is **not** undable and should be used with caution!
    public func dropTable<T: ADDataTable>(_ type: T.Type) throws {
        let sql = "DROP TABLE IF EXISTS \(type.tableName)"
        try execute(sql)
        forgetTable(type.tableName)
    }
    
    /**
     Checks to see if the table has already been created in the SPON database attached to the data provider. If so, the table is recorded with the provider. Otherwise, this function attempts to create the given table.
     
     - Parameters:
         - type: The type of the class to ensure a table exists for.
         - rowData: The raw property values read from an instance of the class used to build the columns.
     - Returns: `true` if the table already exists or if a new table was created, else returns `false`.
     */
    @discardableResult private func ensureTableExists<T: ADDataTable>(type: T.Type, rowData: ADRecord) throws -> Bool {
        
        // Is the table already known to exists?
        if knownTables.contains(type.tableName) {
            // Yes, nothing to do
            return true
        }
        
        // Verify with database that the table hasn't already been created
        if try tableExists(type.tableName) {
            // Yes it does, abort
            knownTables.append(type.tableName)
            return true
        }
        
        // Table does not exist, create it
        let sql = "CREATE TABLE IF NOT EXISTS \(type.tableName) (\(try getColumnSQL(type: type, columns: rowData)))"
        let rc = try execute(sql)
        if rc < 0 {
            throw ADDataProviderError.failedToCreateTable(message: "Table: \(type.tableName) with SQL: \(sql)")
        } else {
            // Successful, add table to know tables
            knownTables.append(type.tableName)
            return true
        }
    }
    
    /**
     Checks to see if the table has already been created in the SPON database attached to the data provider. If so, the table is recorded with the provider. Otherwise, this function attempts to create the given table.
     
     - Parameter box: The `ADInstanceDictionary` containing a coded representation of a Swift object.
     - Returns: `true` if the table already exists or if a new table was created, else returns `false`.
     */
    @discardableResult private func ensureTableExists(forBox box: ADInstanceDictionary) throws -> Bool {
        
        // Is the table already known to exists?
        if knownTables.contains(box.subTableName) {
            // Yes, nothing to do
            return true
        }
        
        // Verify with database that the table hasn't already been created
        if try tableExists(box.subTableName) {
            // Yes it does, abort
            knownTables.append(box.subTableName)
            return true
        }
        
        // Table does not exist, create it
        let sql = "CREATE TABLE IF NOT EXISTS \(box.subTableName) (\(try getColumnSQL(forBox: box)))"
        let rc = try execute(sql)
        if rc < 0 {
            throw ADDataProviderError.failedToCreateTable(message: "Table: \(box.subTableName) with SQL: \(sql)")
        } else {
            // Successful, add table to know tables
            knownTables.append(box.subTableName)
            return true
        }
    }
    
    /**
     Returns a valid SQL statement and matching list of bound parameters needed to insert a new row into the database or to update an existing row of data.
     
     - Parameters:
         - type: The type of object to get
         - data: A dictionary of property names and their corresponding values that need to be persisted to the underlying table.
         - forInsert: A boolean value indicating whether this is an insert or update action.
     - Returns: A tuple containing a valid SQL command to persist data to the underlying table and the bound parameters for the SQL command, if any.
     */
    private func getSQL<T: ADDataTable>(type: T.Type, data: ADRecord, forInsert: Bool = true) -> (String, [Any]?) {
        var sql = ""
        var params:[Any]? = nil
        if forInsert {
            // INSERT INTO tasks(task, categoryID) VALUES ('\(txtTask.text)', 1)
            sql = "INSERT INTO \(type.tableName)("
        } else {
            // UPDATE tasks SET task = ? WHERE categoryID = ?
            sql = "UPDATE \(type.tableName) SET "
        }
        let pkey = type.primaryKey
        var wsql = ""
        var rid:Any?
        var first = true
        for (key, val) in data {
            // Avoid encoding cross references in the stream
            if val is ADDataCrossReference {
                continue
            }
            
            // Primary key handling
            if pkey == key {
                if forInsert {
                    if val is Int && type.primaryKeyType == .autoIncrementingInt && (val as! Int) == -1 {
                        // Do not add this since this is (could be?) an auto-increment value
                        continue
                    }
                } else {
                    // Update - set up WHERE clause
                    wsql += " WHERE " + key + " = ?"
                    rid = val
                    continue
                }
            }
            
            // Set up parameter array - if we get here, then there are parameters
            if first && params == nil {
                params = [AnyObject]()
            }
            if forInsert {
                sql += first ? "\(key)" : ", \(key)"
                wsql += first ? " VALUES (?" : ", ?"
                params!.append(val)
            } else {
                sql += first ? "\(key) = ?" : ", \(key) = ?"
                params!.append(val)
            }
            first = false
        }
        // Finalize SQL
        if forInsert {
            sql += ")" + wsql + ")"
        } else if params != nil && !wsql.isEmpty {
            sql += wsql
            params!.append(rid!)
        }
        return (sql, params)
    }
    
    /**
     Returns a valid SPON statement and matching list of bound parameters needed to insert a new row into the database or to update an existing row of data.
     
     - Parameters:
         - box: A `ADInstanceDictionary` containing an encoded Swift object to generate SQL for.
         - forInsert: A boolean value indicating whether this is an insert or update action.
     - Returns: A tuple containing a valid SQL command to persist data to the underlying table and the bound parameters for the SQL command, if any.
     */
    private func getSQL(forBox box: ADInstanceDictionary, forInsert: Bool = true) -> (String, [Any]?) {
        var sql = ""
        var params:[Any]? = nil
        if forInsert {
            // INSERT INTO tasks(task, categoryID) VALUES ('\(txtTask.text)', 1)
            sql = "INSERT INTO \(box.subTableName)("
        } else {
            // UPDATE tasks SET task = ? WHERE categoryID = ?
            sql = "UPDATE \(box.subTableName) SET "
        }
        let pkey = box.subTablePrimaryKey
        var wsql = ""
        var rid:Any?
        var first = true
        for (key, val) in box.storage {
            // Avoid encoding cross references in the stream
            if val is ADDataCrossReference {
                continue
            }
            
            // Primary key handling
            if pkey == key {
                if forInsert {
                    if val is Int && box.subTablePrimaryKeyType == .autoIncrementingInt && (val as! Int) == -1 {
                        // Do not add this since this is (could be?) an auto-increment value
                        continue
                    }
                } else {
                    // Update - set up WHERE clause
                    wsql += " WHERE " + key + " = ?"
                    rid = val
                    continue
                }
            }
            
            // Set up parameter array - if we get here, then there are parameters
            if first && params == nil {
                params = [AnyObject]()
            }
            if forInsert {
                sql += first ? "\(key)" : ", \(key)"
                wsql += first ? " VALUES (?" : ", ?"
                params!.append(val)
            } else {
                sql += first ? "\(key) = ?" : ", \(key) = ?"
                params!.append(val)
            }
            first = false
        }
        // Finalize SQL
        if forInsert {
            sql += ")" + wsql + ")"
        } else if params != nil && !wsql.isEmpty {
            sql += wsql
            params!.append(rid!)
        }
        return (sql, params)
    }
    
    /**
     Returns a valid SQL fragment for creating the columns, with the correct data type, for the underlying table.
     
     - Parameter type: The type of `ADDataTable` that column information is being gotten for.
     - Parameter columns: A dictionary of property names and their corresponding values for the `ADSQLiteTable` sub-class.
     - Returns: A string containing an SQL fragment for delcaring the columns for the underlying table with the correct data type.
     */
    private func getColumnSQL<T: ADDataTable>(type: T.Type, columns: ADRecord) throws -> String {
        var sql = ""
        for key in columns.keys {
            // Get column value
            if let val = columns[key] {
                // Start building column type
                var col = "'\(key)' "
                
                // Take action based on the value type
                if val is NSNull {
                    // No value provided, raise error
                    throw ADDataProviderError.missingRequiredValue(message: "While attempting to create or update a table schema, the data provider encountered a `nil` value. Use either the `register` or `update` functions with a fully populated default value class instance (with all values set to a default, non-nil value) to create or update the table schema.")
                } else if val is ADDataCrossReference {
                    // This type not stored in table
                    continue
                } else if let box = val as? ADInstanceDictionary {
                    let keyVal = box.storage[box.subTablePrimaryKey]
                    var fkType = "TEXT"
                    
                    if keyVal is Int {
                        fkType = "INTEGER"
                    } else if keyVal is Float || keyVal is Double {
                        fkType = "REAL"
                    } else if keyVal is Bool {
                        fkType = "BOOLEAN"
                    } else if keyVal is Date {
                        fkType = "DATE"
                    } else if keyVal is NSData || keyVal is Data{
                        fkType = "BLOB"
                    }
                    
                    col += "\(fkType) REFERENCES \(box.subTableName)(\(box.subTablePrimaryKey))"
                } else if val is Int {
                    col += "INTEGER"
                } else if val is Float || val is Double {
                    col += "REAL"
                } else if val is Bool {
                    col += "BOOLEAN"
                } else if val is Date {
                    col += "DATE"
                } else if val is NSData || val is Data {
                    col += "BLOB"
                } else {
                    // Default to text
                    col += "TEXT"
                }
                if key == type.primaryKey {
                    // Auto incrementing key?
                    if type.primaryKeyType == .autoIncrementingInt {
                        col += " PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE"
                    } else {
                        col += " PRIMARY KEY NOT NULL UNIQUE"
                    }
                }
                if sql.isEmpty {
                    sql = col
                } else {
                    sql += ", " + col
                }
            } else {
                // No value provided, raise error
                throw ADDataProviderError.missingRequiredValue(message: "While attempting to create or update a table schema, the data provider encountered a `nil` value. Use either the `register` or `update` functions with a fully populated default value class instance (with all values set to a default, non-nil value) to create or update the table schema.")
            }
        }
        return sql
    }
    
    /**
     Returns a valid SQL fragment for creating the columns, with the correct data type, for the underlying table.
     
     - Parameter box: A `ADInstanceDictionary` containing an encoded Swift object to generate SQL column commands for.
     - Returns: A string containing an SQL fragment for delcaring the columns for the underlying table with the correct data type.
     */
    private func getColumnSQL(forBox box: ADInstanceDictionary) throws -> String {
        var sql = ""
        for key in box.storage.keys {
            // Get column value
            if let val = box.storage[key] {
                // Start building column type
                var col = "'\(key)' "
                
                // Take action based on the value type
                if val is NSNull {
                    // No value provided, raise error
                    throw ADDataProviderError.missingRequiredValue(message: "While attempting to create or update a table schema, the data provider encountered a `nil` value. Use either the `register` or `update` functions with a fully populated default value class instance (with all values set to a default, non-nil value) to create or update the table schema.")
                } else if val is ADDataCrossReference {
                    // This type not stored in table
                    continue
                } else if let box = val as? ADInstanceDictionary {
                    let keyVal = box.storage[box.subTablePrimaryKey]
                    var fkType = "TEXT"
                    
                    if keyVal is Int {
                        fkType = "INTEGER"
                    } else if keyVal is Float || keyVal is Double {
                        fkType = "REAL"
                    } else if keyVal is Bool {
                        fkType = "BOOLEAN"
                    } else if keyVal is Date {
                        fkType = "DATE"
                    } else if keyVal is NSData || keyVal is Data{
                        fkType = "BLOB"
                    }
                    
                    col += "\(fkType) REFERENCES \(box.subTableName)(\(box.subTablePrimaryKey)) ON DELETE CASCADE"
                } else if val is Int {
                    col += "INTEGER"
                } else if val is Float || val is Double {
                    col += "REAL"
                } else if val is Bool {
                    col += "BOOLEAN"
                } else if val is Date {
                    col += "DATE"
                } else if val is NSData || val is Data {
                    col += "BLOB"
                } else {
                    // Default to text
                    col += "TEXT"
                }
                if key == box.subTablePrimaryKey {
                    // Auto incrementing key?
                    if box.subTablePrimaryKeyType == .autoIncrementingInt {
                        col += " PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE"
                    } else {
                        col += " PRIMARY KEY NOT NULL UNIQUE"
                    }
                }
                if sql.isEmpty {
                    sql = col
                } else {
                    sql += ", " + col
                }
            } else {
                // No value provided, raise error
                throw ADDataProviderError.missingRequiredValue(message: "While attempting to create or update a table schema, the data provider encountered a `nil` value. Use either the `register` or `update` functions with a fully populated default value class instance (with all values set to a default, non-nil value) to create or update the table schema.")
            }
        }
        return sql
    }
}

