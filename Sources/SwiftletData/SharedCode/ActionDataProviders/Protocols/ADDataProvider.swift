//
//  ADDataProvider.swift
//  ActionControls
//
//  Created by Kevin Mullins on 9/13/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/**
 Defines an Action Data Provider that can be used to read and write data from a given data source.
 
 A `ADDataProvider` provides both light-weight, low-level access to data stored in a SQLite database and high-level access via a Object Relationship Management (ORM) model. Use provided functions to read and write data stored in a `ADRecord` format from and to the database using SQL statements directly.
 
 ## Example:
 ```swift
 let provider = ADDataProvider()
 let record = try provider.query("SELECT * FROM Categories WHERE id = ?", withParameters: [1])
 print(record["name"])
 ```
 
 Optionally, pass a class instance conforming to the `ADDataTable` protocol to the `ADSQLiteProvider` and it will automatically handle reading, writing and deleting data as required.
 
 ## Example:
 ```swift
 let addr1 = Address(addr1: "PO Box 1234", addr2: "", city: "Houston", state: "TX", zip: "77012")
 let addr2 = Address(addr1: "25 Nasa Rd 1", addr2: "Apt #123", city: "Seabrook", state: "TX", zip: "77586")
 
 let p1 = Person(firstName: "John", lastName: "Doe", addresses: ["home":addr1, "work":addr2])
 let p2 = Person(firstName: "Sue", lastName: "Smith", addresses: ["home":addr1, "work":addr2])
 
 let group = Group(name: "Employees", people: [p1, p2])
 try provider.save(group)
 ```
 */
public protocol ADDataProvider: AnyObject {
    
    // MARK: - Public Properties
    /// Is there currently a data source open for the provider.
    var isOpen: Bool { get }
    
    /// Can the data provider write to the given data source.
    var isReadOnly: Bool { get }
    
    /// An array of all tables that have been read from or written to the given data source.
    var knownTables: [String] { get set }
    
    // MARK: - Public Functions
    /**
     Opens the given source file for the data provider.
     
     - Parameters:
         - fileName: The name of the source file to open.
         - fromBundle: Is the source file in the app's Bundle directory.
         - readOnly: Open the source file read only.
     */
    func openSource(_ fileName: String, fromBundle: Bool, readOnly: Bool) throws
    
    /**
     Creates the given source file for the data provider.
     
     - Parameter filename: The name of the source file to create.
    */
    func createSource(_ filename: String) throws
    
    /**
     Saves an in-memory database to the given filename or copies a disk-based database (such as SQLite) to the new filename.
     
     - Parameter filename: The name of the file to save or copy the database to.
    */
    func saveSource(_ filename: String) throws
    
    /// For in-memory data sources, writes the contents of the in-memory source to persistant storage.
    func persist() throws
    
    /// Closes any open data source attached to the data provider.
    func closeSource() throws
    
    /**
     For writable data sources, delete the data source with the specified file name.
     
     - Parameter fileName: The name of the data source to delete.
     */
    func deleteSource(_ fileName: String) throws
    
    /**
     Execute SQL (non-query) command with (optional) parameters and return result code.
     
     - Parameters:
         - sql: The SQL statement to be executed.
         - parameters: An array of optional parameters incase the SQL statement includes bound parameters (indicated by `?` in the SQL Statement).
     - Returns: If executing an `INSERT` command of a record with an `INTEGER` id, the last inserted ID will be returned. For `DELETE` and `UPDATE` commands, a count of number of records modified will be returned. All other commands will return `1` on success and `-1` on failure.
     */
    @discardableResult func execute(_ sql: String, withParameters parameters: [Any]?) throws -> Int
    
    /**
     Run an SQL query with (parameters) parameters and returns an array of dictionaries where the keys are the column names.
     
     - Parameters:
         - sql: The SQL statement to be executed.
         - parameters: An array of optional parameters incase the SQL statement includes bound parameters (indicated by `?` in the SQL Statement).
     - Returns: An empty array if the query resulted in no rows. Otherwise, an array of dictionaries where each dictioanry key is a column name and the value is the column value.
     */
    func query(_ sql: String, withParameters parameters: [Any]?) throws -> ADRecordSet
    
    /**
     Checks to see if the given table exists in the SQLite database.
     
     - Parameter tableName: The name the table to check.
     - Returns: `true` if the table exists, else `false.
     */
    func tableExists(_ tableName: String) throws -> Bool
    
    /**
     Counts the number of records in a given table, optionally filtered by a given set of contraints where a "table" represents the base unit of data (for example a SQLite table or JSON node) for the source of the data provider. 
     
     - Parameters:
         - table: The name of the table to count records for.
         - filter: The optional filter criteria to be used in fetching the data. Specify the filter criteria in the form of a valid SQL WHERE clause (without the actual `WHERE` keyword). If this parameter is omitted or a blank string is provided, all rows will be fetched.
         - parameters: An array of optional parameters incase the SQL statement includes bound parameters (indicated by `?` in the SQL Statement).
     - Returns: An integer value indicating the total number of rows, if no filter criteria was provided, or the number of rows matching the provided filter criteria. If the table doesn't exist, 0 is returned.
     */
    func countRows(inTable table: String, filteredBy filter: String, withParameters parameters: [Any]?) throws -> Int
    
    /**
     Gets the largest used number for the given integer primary key of the given table.
     
     - Parameters:
         - table: The name of the table to get the last ID from.
         - primaryKey: The name of the primary key.
     - Returns: The largest used number for the given primary key or zero if no record has been written to the table yet.
     */
    func lastIntID(forTable table: String, withKey primaryKey: String) throws -> Int
    
    /**
     Gets the last auto generated integer ID for the given table.
     
     - Parameters:
         - table: The name of the table to get the last ID from.
         - Returns: The last auto generated integer id or zero if no data has been saved to the table or if the table does not have an auto generated integer primary key.
     */
    func lastAutoID(forTable table: String) throws -> Int
    
    // MARK: - ORM Functions
    /**
     Registers the given `ADDataTable` class schema with the data provider and creates a table for the class if it doesn't already exist.
     
     - Remark: Classes are usually registered when an app first starts, directly after a database is opened.
     - Parameters:
         - type: The type of the class to register.
         - instance: An instance of the type with all properties set to the default values that you want to have added to the data source.
     */
    func registerTableSchema<T: ADDataTable>(_ type: T.Type, withDefaultValues instance: T) throws
    
    /**
     Attempts to modify the data source table schema to match the schema of the given `ADDataTable` class if the schema has changed. If the table does not exist, it will attempt to be registered with the data source. If any new columns have been added, the default values will be set from the given defaults.
     
     - Parameters:
         - type: The type of the class to update the schema of.
         - instance: An instance of the type with all properties set to the default values that you want to have added to the data source.
     */
    func updateTableSchema<T: ADDataTable>(_ type: T.Type, withDefaultValues instance: T) throws
    
    /**
     Checks to see if a row matching the given primary key exists in the underlying SQLite table.
     
     - Parameters:
     - type: The `ADDataTable` class to check if the row exists for.
     - key: The primary key value to search for.
     - Returns: `true` if a row matching the primary key is found, else `false`.
     */
    func hasRow<T: ADDataTable>(forType type: T.Type, matchingPrimaryKey key: Any) throws -> Bool
    
    /**
     Return the count of rows in the table, or the count of rows matching a specific filter criteria, if one was provided.
     
     - Parameters:
         - type: A class conforming to the `ADDataTable` protocol to count rows for.
         - filter: The optional filter criteria to be used in fetching the data. Specify the filter criteria in the form of a valid SQL `WHERE` clause (without the actual `WHERE` keyword). If this parameter is omitted or a blank string is provided, all rows will be fetched.
         - parameters: An array of optional parameters incase the SQL statement includes bound parameters (indicated by `?` in the SQL Statement).
     - Returns: An integer value indicating the total number of rows or rows matching the optional filter in the given table.
     */
    func rowCount<T: ADDataTable>(forType type: T.Type, filterBy filter: String, withParameters parameters: [Any]?) throws -> Int
    
    /**
     Creates an instance of the given `ADDataTable` class automatically setting the **primaryKey** field based on the value of the **primaryKeyType**.
     
     - Parameter type: The class conforming to the `ADDataTable` protocol to create an instance of.
     - Returns: A new instance of the given class with the **primaryKey** automatically set.
     */
    func make <T: ADDataTable>(_ type: T.Type) throws -> T
    
    /**
     Returns a value for the **primaryKey** field based on the value of the **primaryKeyType** for a class conforming to the `ADDataTable` protocol.
     
     - Parameter type: The class conforming to the `ADDataTable` protocol to create primary key for.
     - Returns: A new primary key value if it can be generated, else returns `nil`.
     */
    func makeID<T: ADDataTable>(_ type: T.Type) -> Any?
    
    /**
     Returns all information about a given table in the data source including all of the columns and their types.
     
     - Parameter name: The name of the table to return the schema for.
     - Returns: A `ADTableSchema` instance describing the requested table.
     */
    func getTableSchema(forTableName name: String) throws -> ADTableSchema
    
    /**
     Saves the given class conforming to the `ADDataTable` protocol to the data source. If the data source does not contain a table named in the **tableName** property, one will be created first. If a record is not on file matching the **primaryKey** value, a new record will be created, else the existing record will be updated.
     
     - Parameter value: The class instance to save to the database.
     - Returns: If inserting a record with an `INTEGER` id, the last inserted ID will be returned, else the primary key value will be returned.
     */
    func save<T: ADDataTable>(_ value: T) throws -> Any
    
    /**
    Saves the given array of class instances conforming to the `ADDataTable` protocol to the data source. If the data source does not contain a table named in the **tableName** property, one will be created first. If a record is not on file matching the **primaryKey** value, a new record will be created, else the existing record will be updated.
    
    - Parameter values: The array of class instances to save to the data source.
    - Remark: Uses a transaction to process all data source changes in a single batch. If an error occurs, all changes will be rolled-back and the data source will not be modified.
    */
    func save<T: ADDataTable>(_ values: [T]) throws
    
    /**
     Returns rows from the data source of the given class type optionally filtered, sorted and limited to a specific range of results.
     
     - Parameters:
         - type: A class conforming to the `ADDataTable` protocol to store the records in.
         - filter: The optional filter criteria to be used in fetching the data. Specify in the form of a valid SQL `WHERE` clause (without the actual `WHERE` keyword). If this parameter is omitted or a blank string is provided, all rows will be fetched.
         - order: The optional sorting criteria to be used in fetching the data. Specify in the form of a valid SQL `ORDER BY` clause (without the actual `ORDER BY` keyword). If this parameter is omitted or a blank string is provided, no sorting will be applied.
         - start: The starting index for the returned results. If omitted or zero, the result set starts with the first record.
         - limit: Limits the returned results to a maximum number. If omitted or zero, all matching results are returned.
         - parameters: An array of optional parameters incase the SQL statement includes bound parameters (indicated by `?` in the SQL Statement).
     - Returns: An array of matching records in the given class type or an empty array if no matching records were found.
     */
    func getRows<T: ADDataTable>(ofType type: T.Type, fliteredBy filter: String, orderedBy order: String, startingAt start: Int, limitedTo limit: Int, withParameters parameters: [Any]?) throws -> [T]
    
    /**
     Returns rows from the data source of the given class type matching the given SQL statement.
     
     - Parameters:
         - type: A class conforming to the `ADDataTable` protocol to store the records in.
         - sql: A valid SQL statement used to pull matching records from the database.
         - parameters: An array of optional parameters incase the SQL statement includes bound parameters (indicated by `?` in the SQL Statement).
     - Returns: An array of matching records in the given class type or an empty array if no matching records were found.
     */
    func getRows<T: ADDataTable>(ofType type: T.Type, matchingSQL sql: String, withParameters parameters: [Any]?) throws -> [T]
    
    /**
     Returns a row from the SQLite database of the given class type matching the given primary key value.
     
     - Parameters:
         - type: A class conforming to the `ADDataTable` protocol to store the records in.
         - key: The primary key value to return a record for.
     - Returns: A record of the requested type if found or `nil` if not found.
     */
    func getRow<T: ADDataTable>(ofType type: T.Type, forPrimaryKeyValue key: Any) throws -> T?
    
    /**
     Returns a row from the data source of the given class type optionally filtered and limited to a specific range of results.
     
     - Parameters:
         - type: A class conforming to the `ADDataTable` protocol to store the records in.
         - index: The starting index of the record to return.
         - filter: The optional filter criteria to be used in fetching the data. Specify in the form of a valid SQL `WHERE` clause (without the actual `WHERE` keyword). If this parameter is omitted or a blank string is provided, all rows will be fetched.
         - order: The optional sorting criteria to be used in fetching the data. Specify in the form of a valid SQL `ORDER BY` clause (without the actual `ORDER BY` keyword). If this parameter is omitted or a blank string is provided, no sorting will be applied.
         - parameters: An array of optional parameters incase the SQL statement includes bound parameters (indicated by `?` in the SQL Statement).
     - Returns: A record of the requested type if found or `nil` if not found.
     */
    func getRow<T: ADDataTable>(ofType type: T.Type, atIndex index: Int, fliteredBy filter: String, orderedBy order: String, withParameters parameters: [Any]?) throws -> T?
    
    /**
     Deletes the row matching the given record from the SQLite database.
     
     - Parameter value: An instance of a class conforming to the `ADDataTable` protocol to delete from the data source.
     */
    func delete<T: ADDataTable>(_ value: T) throws
    
    /**
     Deletes the given set of records from the data source.
     
     - Remark: Uses a transaction to process all data source changes in a single batch. If an error occurs, all changes will be rolled-back and the data source will not be modified.
     */
    func delete<T: ADDataTable>(_ values: [T]) throws
    
    /// Drops the underlying table from the data source, completely removing all stored data in the table as well as the table itself.
    /// - Warning: This command is **not** undable and should be used with caution!
    func dropTable<T: ADDataTable>(_ type: T.Type) throws
    
    /// Starts an explicit transaction to process a batch of data source changes. Once started, the transaction will remain open until it is either committed (via `endTransaction`) or rolled-back (via `rollbackTransaction).
    func beginTransaction() throws
    
    /// Attempts to commit any chages to the data source and close the current transaction that was opened using `beginTransaction`.
    func endTransaction() throws
    
    /// Ends the current transaction (opened using `beginTransaction`) and undoes any changes made to the data source since the transaction was opened.
    func rollbackTransaction() throws
}
