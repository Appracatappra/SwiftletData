//
//  ADCrossReference.swift
//  ActionControls
//
//  Created by Kevin Mullins on 10/11/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/**
 Creates and maintains a one-to-many or many-to-many cross reference relationship between two `ADDataTable` instances that can be stored in or read from a `ADDataProvider`.
 
 ## Example:
 The following creates a relationship between the `Group` and `Person` tables (both conforming to `ADDataTable`) on the `Group.people` property:
 
 ```swift
 import Foundation
 import ActionData
 
 class Group: ADDataTable {
 
     static var tableName = "Groups"
     static var primaryKey = "id"
     static var primaryKeyType: ADDataTableKeyType = .computedInt
 
     var id = ADSQLiteProvider.shared.makeID(Group.self) as! Int
     var name = ""
     var people = ADCrossReference<Person>(name: "PeopleInGroup", leftKeyName: "groupID", rightKeyName: "personID")
 
     required init() {
 
     }
 }
 ```
 Instance of the `Person` table stored in `people` will be cross referenced in the `PeopleInGroup` table where `groupID` is the `Group` instance's `id` and `personID` is the `Person` instances `id`.
 
 - Warning: `ADCrossReference` was meant to work with a small number of relationships **only**, because all cross referenced items are always read into memory when the parent object is loaded. Care should be taken to keep from overflowing memory.
 */
public struct ADCrossReference<T: ADDataTable>: ADDataCrossReference, IteratorProtocol, Sequence {
    // Holds a reference to  the base table being itterated in a sequence.
    public typealias Element = T
    
    // MARK: - Properties
    private var index = 0
    
    /// The name of the cross reference table.
    public var crossReferenceName: String = ""
    
    /// The name of the left-side key used to store the primary key of the `ADDataTable` on the left side of the relationship.
    public var leftKeyName: String = "leftID"
    
    /// The name of the right-side key used to store the primary key of the `ADDataTable` on the right side of the relationship.
    public var rightKeyName: String = "rightID"
    
    /// Stores all child `ADDataTable` instances that are a part of the cross reference relationship to the left-side primary key value.
    public var storage: [T] = []
    
    /// Provides quick access to the items in the `storage` property.
    public subscript(_ index: Int) -> T {
        get {
            return storage[index]
        }
        set {
            storage[index] = newValue
        }
    }
    
    /// Returns the number of `ADDataTable` instances in the cross reference.
    public var count: Int {
        return storage.count
    }
    
    // MARK: - Initializers
    /**
     Creates a new instance of the `ADCrossReference` with the given table name and key names.
     
     ## Example
     ```swift
     var people = ADCrossReference<Person>(name: "PeopleInGroup", leftKeyName: "groupID", rightKeyName: "personID")
     ```
     
     - Parameters:
         - name: The name of the cross reference table.
         - leftKeyName: The name of the left-side key used to store the primary key of the `ADDataTable` on the left side of the relationship. The default value is `leftID`.
         - rightKeyName: The name of the right-side key used to store the primary key of the `ADDataTable` on the right side of the relationship. The default value is `rightID`.
     */
    public init(name: String, leftKeyName: String = "leftID", rightKeyName: String = "rightID") {
        self.crossReferenceName = name
        self.leftKeyName = leftKeyName
        self.rightKeyName = rightKeyName
    }
    
    // MARK: - Functions
    /**
     Returns the next item in a sequence.
     
     - Returns: The next `ADDataTable` in the sequence.
     */
    public mutating func next() -> T? {
        defer {
            index += 1
        }
        
        if (index >= storage.count) {
            index = 0
            return nil
        } else {
            return storage[index]
        }
    }
    
    /**
     Adds the given `ADDataTable` instance to the cross reference's `storage`.
     
     - Parameter item: The `ADDataTable` instance to add.
     */
    public mutating func append(_ item: T) {
        storage.append(item)
    }
    
    /**
     Removes all `ADDataTable` instances from the reference's `storage`.
     */
    public mutating func removeAll() {
        storage.removeAll()
    }
    
    /**
     Removes the given `ADDataTable` instance from the reference's `storage`.
     
     - Parameter at: The index to remove the `ADDataTable` from.
     */
    public mutating func remove(at:Int) {
        storage.remove(at: at)
    }
    
    /**
     Ensures the given cross reference table exists in the given data provider and left-side key value and creates it if required.
     
     - Parameters:
         - provider: The `ADDataProvider` to see if the cross reference exists in.
         - leftKey: The left-side key value to build the cross reference on.
     
     - Returns: `true` if the table exists or was successfully created, else returns `false`.
     */
    @discardableResult public func ensureCrossReferenceExists(in provider: ADDataProvider, forKeyValue leftKey: Any) throws -> Bool {
        
        // Is the table already known to exists?
        if provider.knownTables.contains(crossReferenceName) {
            // Yes, nothing to do
            return true
        }
        
        // Verify with database that the table hasn't already been created
        if try provider.tableExists(crossReferenceName) {
            // Yes it does, abort
            provider.knownTables.append(crossReferenceName)
            return true
        }
        
        // Get a sample primary key value for the stored item
        let instance = T()
        let encoder = ADSQLEncoder()
        let data = try encoder.encode(instance) as! ADRecord
        let rightKey = data[T.primaryKey]!
        
        // Table does not exist, create it
        let sql = "CREATE TABLE IF NOT EXISTS \(crossReferenceName) (\(getColumnSQL(forKey: leftKeyName, withValue: leftKey)), \(getColumnSQL(forKey: rightKeyName, withValue: rightKey)))"
        let rc = try provider.execute(sql, withParameters: nil)
        if rc < 0 {
            throw ADDataProviderError.failedToCreateTable(message: "Cross Reference: \(crossReferenceName) with SQL: \(sql)")
        } else {
            // Successful, add table to know tables
            provider.knownTables.append(crossReferenceName)
            return true
        }
    }
    
    /**
     Removes all cross references for the given key value from the given data provider.
     
     - Parameters:
         - provider: The `ADDataProvider` to remove the cross references from.
         - key: The left-side key value to delete the values for.
     */
    public func delete(from provider: ADDataProvider, forKeyValue key:Any) throws {
        let sql = "DELETE FROM \(crossReferenceName) WHERE \(leftKeyName) = ?"
        try provider.execute(sql, withParameters: [key])
    }
    
    /**
     Saves the given cross references to the data provider for the give key value. The cross reference table will automatically be created if it doesn't already exist.
     
     - Parameters:
         - provider: The provider to save values to the data source.
         - leftKey: The left-side key value to create the cross reference on.
     */
    public func save(to provider: ADDataProvider, forKeyValue leftKey: Any) throws {
        
        // Ensure the cross reference table exists
        try ensureCrossReferenceExists(in: provider, forKeyValue: leftKey)
        
        // Remove all existing references for this key
        try delete(from: provider, forKeyValue: leftKey)
        
        // Process all items
        for item in storage {
            let rightKey = try provider.save(item)
            let sql = "INSERT INTO \(crossReferenceName) VALUES (?,?);"
            try provider.execute(sql, withParameters: [leftKey, rightKey])
        }
    }
    
    /**
     Loads all cross referenced `ADDataTable` instances for the given cross reference based on the given key value.
     
     - Parameters:
         - provider: The `ADDataProvider` to load the `ADDataTable` instances from.
         - key: The left-side key value to load the cross reference on.
     */
    public mutating func load(from provider: ADDataProvider, forKeyValue key:Any) throws {
        
        // Empty storage
        storage = []
        
        // Load item keys
        let sql = "SELECT \(rightKeyName) FROM \(crossReferenceName) WHERE \(leftKeyName) = ?"
        let records = try provider.query(sql, withParameters: [key])
        
        // Process all returned item
        for record in records {
            let itemKey = record[rightKeyName]!
            if let item = try provider.getRow(ofType: T.self, forPrimaryKeyValue: itemKey) {
                storage.append(item)
            }
        }
    }
    
    /**
     Creates the SQL fragment for the given column name and value type.
     
     - Parameters:
         - key: The name of the column to create SQL for.
         - keyVal: The value of the key column.
     
     - Returns: A SQL fragment required to store a given key of a given type.
     */
    private func getColumnSQL(forKey key:String, withValue keyVal: Any) -> String {
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
        
        return "'\(key)' \(fkType)"
    }
}
