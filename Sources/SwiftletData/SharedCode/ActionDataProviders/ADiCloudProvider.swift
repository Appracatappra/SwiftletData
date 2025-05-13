//
//  ADiCloudProvider.swift
//  ActionData iOS
//
//  Created by Kevin Mullins on 3/4/19.
//

import Foundation
import SwiftUI
import SwiftletUtilities
import CloudKit
import LogManager

/**
 The `ADiCloudProvider` provides both light-weight, low-level access to data stored in a iCloud Database Container (public or private) and high-level access via a **Object Relationship Management** (ORM) model. Use provided functions to read and write data stored in a `ADRecord` format from and to the database using SQL like statements directly.
   
 Optionally, pass a class instance conforming to the `ADDataTable` protocol to the `ADiCloudProvider` and it will automatically handle reading, writing and deleting data as required.
  
 ### Example:
 ```swift
 let addr1 = Address(addr1: "PO Box 1234", addr2: "", city: "Houston", state: "TX", zip: "77012")
 let addr2 = Address(addr1: "25 Nasa Rd 1", addr2: "Apt #123", city: "Seabrook", state: "TX", zip: "77586")
  
 let p1 = Person(firstName: "John", lastName: "Doe", addresses: ["home":addr1, "work":addr2])
 let p2 = Person(firstName: "Sue", lastName: "Smith", addresses: ["home":addr1, "work":addr2])
  
 let group = Group(name: "Employees", people: [p1, p2])
 try ADiCloudProvider.shared.save(group)
 ```

 The following would read the data back for any modified records after a given date/time from iCloud:

 ```swift
 let timeOfLastCacheUpdate = Date()
 try ADiCloudProvider.shared.loadRows(ofType: Group.self, matchingQuery: "modificationDate >= %@", sortBy: "modificationDate", withParameters: [timeOfLastCacheUpdate]) { records, error in
     // Ensure the records were loaded
     guard error == nil else {
         print("Error loading the Groups: \(String(describing: error))")
         return
     }
     
     // Was a record returned?
     if let records = records {
         DispatchQueue.main.async {
             for record in records {
                 ...
             }
         }
     }
 }
 ```

 - Remark: The `ADiCloudProvider` will automatically create any required iCloud Table Schemas from a class instance if one does not already exist. In addition, `ADiCloudProvider` contains routines to preregister or update the schema classes conforming to the `ADDataTable` protocol which will build or modify the database schemas as required.
 */
open class ADiCloudProvider {
    
    // MARK: - Type Aliases
    /// Defines a type alias returned from a call to a CloudKit database function.
    public typealias CloudKitRecordCompletionHandler = (CKRecord?,Error?) -> Void
    
    /// Defines a type alias returned from a call to a CloudKit database function.
    public typealias CloudKitRecordIDCompletionHandler = (CKRecord.ID?,Error?) -> Void
    
    /// Defines a type alias returned from a call to a CloudKit database function.
    public typealias CloudKitRecordSetCompletionHandler = ([CKRecord]?,Error?) -> Void
    
    // MARK: - Static Properties
    // Holds the last stated access to cloudkit
    nonisolated(unsafe) private static var cloudKitAccountStatus:CKAccountStatus = .couldNotDetermine
    
    /// If `true` CloudKit is available, else it isn't.
    public var isCloudKitAvailable:Bool {
        
        // Create a threading group
        let availabilityGroup = DispatchGroup()
        
        // Attempt to get the CloudKit account status.
        availabilityGroup.enter()
        CKContainer.default().accountStatus { (accountStatus, error) in
            
            // Was there an error?
            if error != nil {
                // Unable to check status
                ADiCloudProvider.cloudKitAccountStatus = .couldNotDetermine
            } else {
                // Save status
                ADiCloudProvider.cloudKitAccountStatus = accountStatus
            }
            
            availabilityGroup.leave()
        }
        
        // Wait until the thread returns
        availabilityGroup.wait()
        
        switch cloudKitAccountStatus {
        case .available:
            return true
        case .couldNotDetermine, .noAccount:
            return false
        case .restricted:
            return false
        case .temporarilyUnavailable:
            return false
        @unknown default:
            return false
        }
    }
    
    // MARK: - Static Functions
    /**
     Displays an error alert to the user when error occurrs trying to read, write or delete from CloudKit.
     
     - Parameters:
         - appName: The name of the app to display the alert in.
         - action: The action that was trying to be performed.
         - showMessage: The closure to handle showing the alert to the user.
     */
    public static func ShowCloudKitAccessAlert(appName:String, for action:String, showMessage: @escaping (String, String)-> Void) {

        // Attempt to get the CloudKit account status.
        CKContainer.default().accountStatus { (accountStatus, error) in
            var cloudKitAccountStatus:CKAccountStatus = .couldNotDetermine
            var description = ""

            if let error = error {
                // Unable to check status
                cloudKitAccountStatus = .couldNotDetermine
                Log.error(subsystem: "ADiCloudprovider", category: "CloudKit", "Unable to determine the user's CloudKit account status: \(error)")
            } else {
                // Save status
                cloudKitAccountStatus = accountStatus
            }

            switch cloudKitAccountStatus {
            case .available:
                return
            case .couldNotDetermine, .noAccount:
                description = "You must be logged into an iCloud account in Settings before \(appName) can save, load or delete items."
            case .restricted:
                description = "Your iCloud account doesn't have the required rights to write to your iCloud Database."
            case .temporarilyUnavailable:
                description = "An unknown issue occurred while trying to access your iCloud account."
            @unknown default:
                description = "An unknown issue occurred while trying to access your iCloud account."
            }

            DispatchQueue.main.async {
                let title = "Unable to \(action)"
                showMessage(title, description)
            }
        }

    }
    
    /**
     Displayes an error alert to the user when error occurrs trying to read, write or delete from CloudKit.
     
     - Parameters:
         - appName: The name of the app to display the alert in.
         - action: The action that was trying to be performed.
         - dbError: The Error that was initially thrown.
         - showMessage: The closure to handle showing the alert to the user.
    */
    public static func showCloudKitErrorAlert(appName:String, for action:String, with dbError:Error, showMessage: @escaping (String, String)-> Void) {
        
        // Attempt to get the CloudKit account status.
        CKContainer.default().accountStatus { (accountStatus, error) in
            var cloudKitAccountStatus:CKAccountStatus = .couldNotDetermine
            var description = ""
            
            if let error = error {
                // Unable to check status
                cloudKitAccountStatus = .couldNotDetermine
                Log.error(subsystem: "ADiCloudProvider", category: "CloudKit", "Unable to determine the user's CloudKit account status: \(error)")
            } else {
                // Save status
                cloudKitAccountStatus = accountStatus
            }
            
            switch cloudKitAccountStatus {
            case .available:
                description = "The following error occurred while trying to access your iCloud database: \(dbError)"
            case .couldNotDetermine, .noAccount:
                description = "You must be logged into an iCloud account in Settings before \(appName) can save, load or delete items."
            case .restricted:
                description = "Your iCloud account doesn't have the required rights to write to your iCloud Database."
            case .temporarilyUnavailable:
                description = "An unknown issue occurred while trying to access your CloudKit database: \(dbError)"
            @unknown default:
                description = "An unknown issue occurred while trying to access your CloudKit database: \(dbError)"
            }
            
            DispatchQueue.main.async {
                let title = "Unable to \(action)"
                showMessage(title, description)
            }
        }
        
    }
    
    // MARK: - Static Properties
    /// Provides access to a common, shared instance of the `ADiCloudProvider`. For app's that are working with a single private iCloud database, they can use this instance instead of creating their own instance of a `ADiCloudProvider`.
    nonisolated(unsafe) public static let shared = ADiCloudProvider()
    
    /// Provides access to a common, shared instance of the `ADiCloudProvider`. For app's that are working with a single public iCloud database, they can use this instance instead of creating their own instance of a `ADiCloudProvider`.
    nonisolated(unsafe) public static let sharedPublic = ADiCloudProvider()
    
    /**
     The current value of an auto incrementing integer key used for CloudKit records.
     
     HACK: This is currently just a quick fix hack and needs to be written to correctly get the required value.
     
     - Returns: An integer value for the next available auto incrementing key.
    */
    public static var autoIncrementingKeyValue:Int {
        get { return UserDefaults.standard.integer(forKey: "ClouKitAutoIncVal")}
        set {
            UserDefaults.standard.set(newValue, forKey: "ClouKitAutoIncVal")
        }
    }
    
    /// Returns `true` if CloudKit is available on the given device, else returns `false`.
    public static var isCloudKitAvailable:Bool {
        return FileManager.default.ubiquityIdentityToken != nil
    }
    
    // MARK: - Private properties
    /// Internal access to the iCloud container that is currently open.
    private var iCloudContainer:CKContainer? = nil
    
    /// Internal access to the iCloud database that is currently open.
    private var iCloudDatabase:CKDatabase? = nil
    
    /// Holds the cursor returned from a large data pull.
    private var continuationCursor:CKQueryOperation.Cursor? = nil
    
    /// Holds the number of results that will be returned for a continuation query.
    private var continuationLimit:Int = CKQueryOperation.maximumResults
    
    /// Returns `true` if the data provider can write to the currently open iCloud database, else returns `false`.
    public private(set) var isReadOnly: Bool = false
    
    /// Holds the current user's CloudKit account status.
    public private(set) var cloudKitAccountStatus:CKAccountStatus = .couldNotDetermine
    
    // MARK: - Computed Properties
    /// Returns `true` if a iCloud database currently open in the data provider, else returns `false`.
    public var isOpen: Bool {
        return (iCloudDatabase != nil)
    }
    
    /// Are there more rows waiting after performing a fetch of records that resulted in a large number of records being returned?
    public var hasMoreRows:Bool {
        return (continuationCursor != nil)
    }
    
    // MARK: - Initializers
    public init() {
        
        // Attempt to get the CloudKit account status.
        CKContainer.default().accountStatus { [weak self] (accountStatus, error) in
            if let error = error {
                // Unable to check status
                self?.cloudKitAccountStatus = .couldNotDetermine
                Log.error(subsystem: "ADiCloudProvider", category: "init", "Unable to determine the user's CloudKit account status: \(error)")
            } else {
                // Save status
                self?.cloudKitAccountStatus = accountStatus
            }
        }
    }
    
    // MARK: - Functions
    /**
     Opens a CloudKit container and database with the given parameters.
     
     - Parameters:
         - containerIdentifier: The ID of the container to open or `nil` to open the app's default container.
         - type: The type of database to open from the container: private, public or shared.
    */
    public func openSource(containerIdentifier:String? = nil, type:ADiCloudDatabaseType = .privateDatabase) throws {
        
        // Open the requested container
        if let identifier = containerIdentifier {
            // Attempt to open the requested container.
            iCloudContainer = CKContainer(identifier: identifier)
            
            // Opened?
            if iCloudContainer == nil {
                throw ADDataProviderError.unableToOpenDataSource
            }
        } else {
            // Open the default container.
            iCloudContainer = CKContainer.default()
        }
        
        // Open the requested database
        switch type {
        case .privateDatabase:
            iCloudDatabase = iCloudContainer?.privateCloudDatabase
        case .publicDatabase:
            iCloudDatabase = iCloudContainer?.publicCloudDatabase
        case .sharedDatabase:
            iCloudDatabase = iCloudContainer?.sharedCloudDatabase
        }
    }
    
    /// Closes any open iCloud container and database.
    public func closeSource() {

        iCloudDatabase = nil
        iCloudContainer = nil
    }
    
    /**
    Gets the largest used number for the given integer primary key of the given table.
    
    ## Example:
    ```swift
    let lastID = try ADiCloudProvider.shared.lastIntID(forTable: "Person", withKey: "ID")
    ```
    
    - Remark: This function works with integer primary keys that are not marked AUTOINCREMENT and is useful when the data being stored in a database needs to know the next available ID before a record has been saved.
    
    - Parameters:
        - table: The name of the table to get the last ID from.
        - primaryKey: The name of the primary key.
    - Returns: The largest used number for the given primary key or zero if no record has been written to the table yet.
    */
    public func lastIntID(forTable table: String, withKey primaryKey: String) throws -> Int {
        
        return UserDefaults.standard.integer(forKey: "ClouKitAutoIncVal")
    }
    
    /**
     Builds a CloudKit record from the given `ADRecord` encoded data dictionary.
     
     - Parameters:
         - tableName: The name of the table to save the record to.
         - data: The data to convert to a CloudKit record.
         - key: The primary key for the record.
     - Returns: The CloudKit record for the given dataset.
     */
    private func buildCloudKitRecord(for tableName:String, from data:ADRecord, with key:Any) throws -> CKRecord {
        
        // Build CloudKit record
        let recordKey = CKRecord.ID(recordName: "\(key)")
        let record = CKRecord(recordType: tableName, recordID: recordKey)
        
        // Process all data in the record.
        for (key,info) in data {
            // Copy the data over to the CloudKit record
            if let text = info as? String {
                record[key] = NSString(string: text)
            } else if let number = info as? Float {
                record[key] = NSNumber(value: number)
            } else if let number = info as? Double {
                record[key] = NSNumber(value: number)
            } else if let number = info as? Int {
                record[key] = NSNumber(value: number)
            } else if let value = info as? Bool {
                let text = value ? "$#1" : "$#0"
                record[key] = NSString(string: text)
            } else {
                throw ADDataProviderError.failedToPrepareSQL(message: "Could not convert field `\(key)` to a valid CloudKit value.")
            }
        }
        
        // Return new record
        return record
    }
    
    
    /// Updates an existing `CKRecord` pulled from CloudKit with the values from the in memory `ADDataTable` instance of the record.
    ///
    /// This function is used to update an existing record instead of having to delete the record and resave it as a brand new record.
    ///
    /// - Parameters:
    ///   - record: The `CKRecord` read from CloudKit to update.
    ///   - data: The `ADData` from the in-memory `ADDataTable` to update the record with.
    /// - Returns: The modified `CKRecord` with the new values.
    private func updateCloudKitRecord(for record:CKRecord, from data:ADRecord) throws -> CKRecord {
        
        // Write new values into existing CloudKit record.
        for (key,info) in data {
            // Copy the data over to the CloudKit record
            if let text = info as? String {
                record[key] = NSString(string: text)
            } else if let number = info as? Float {
                record[key] = NSNumber(value: number)
            } else if let number = info as? Double {
                record[key] = NSNumber(value: number)
            } else if let number = info as? Int {
                record[key] = NSNumber(value: number)
            } else if let value = info as? Bool {
                let text = value ? "$#1" : "$#0"
                record[key] = NSString(string: text)
            } else {
                throw ADDataProviderError.failedToPrepareSQL(message: "Could not convert field `\(key)` to a valid CloudKit value.")
            }
        }
        
        // Return new record
        return record
    }
    
    /**
     Attempts to convert the given CloudKit record to a `ADRecord`.
     
     - Parameter record: The `CKRecord` to convert.
     - Returns: A `ADRecord` containing the values from the CloudKit record.
     */
    private func buildADRecord(from record:CKRecord) throws -> ADRecord {
        var data:ADRecord = [:]
        
        for (key, info) in record {
            if let text = info as? String {
                switch text {
                case "$#1":
                    data[key] = true
                case "$#0":
                    data[key] = false
                default:
                    data[key] = text
                }
            } else if let value = info as? Float {
                data[key] = value
            } else if let value = info as? Double {
                data[key] = value
            } else if let value = info as? Int64 {
                data[key] = Int(value)
            } else {
                throw ADDataProviderError.unableToConvertValue(message: "Couldn't move \(info) for key \(key).")
            }
        }
        
        // Return results
        return data
    }
    
    // MARK: - ORM Functions
    /**
     Creates an instance of the given `ADDataTable` class automatically setting the **primaryKey** field based on the value of the **primaryKeyType**.
     
     ## Example:
     ```swift
     var category = try ADiCloudProvider.shared.make(Category.self)
     ```
     
     - Parameter type: The class conforming to the `ADDataTable` protocol to create an instance of.
     - Returns: A new instance of the given class with the **primaryKey** automatically set.
     */
    public func make <T: ADDataTable>(_ type: T.Type) throws -> T {
        
        // Build a new instance of the record and encode it
        let instance = type.init()
        var record = try ADSQLEncoder().encode(instance) as! ADRecord
        
        // Take action based on the primary key type
        switch type.primaryKeyType {
        case .autoUUIDString:
            let id = UUID().uuidString
            record[type.primaryKey] = id
        case .autoIncrementingInt:
            let id = ADiCloudProvider.autoIncrementingKeyValue + 1
            record[type.primaryKey] = id
            ADiCloudProvider.autoIncrementingKeyValue = id
        case .computedInt:
            let id = try lastIntID(forTable: type.tableName, withKey: type.primaryKey) + 1
            record[type.primaryKey] = id
        default:
            break
        }
        
        // Convert back into a class and return
        return try ADSQLDecoder().decode(type, from: record)
    }
    
    /**
     Returns a value for the **primaryKey** field based on the value of the **primaryKeyType** for a class conforming to the `ADDataTable` protocol.
     
     ## Example:
     ```swift
     let id = ADiCloudProvider.shared.makeID(Category.self) as! Int
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
            let id = ADiCloudProvider.autoIncrementingKeyValue + 1
            ADiCloudProvider.autoIncrementingKeyValue  = id
            return id
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
     Tests to see if the given key holds a valid value to be a key in a CloudKit database.
     
     - Parameter key: The key value to test.
     - Returns: `true` if the value is not valid for a key value, else returns `false`.
    */
    public func isUndefined(key:Any) -> Bool {
        
        // Check to see if the key value is empty.
        if let value = key as? Float {
            return value < 1.0
        } else if let value = key as? Double {
            return value < 1.0
        } else if let value = key as? Int {
            return value < 1
        } else if let value = key as? Int64 {
            return value < 1
        } else if let value = key as? String {
            return value.isEmpty
        }
        
        // Default to undefined
        return true
    }
    
    /**
     Registers the given `ADDataTable` class schema with the data provider and creates a table for the class if it doesn't already exist.
     
     ## Example:
     ```swift
     try ADiCloudProvider.shared.registerTableSchema(Category.self)
     ```
     
     - Remark: Classes are usually registered when an app first starts, directly after a database is opened.
     - Parameters:
         - type: The type of the class to register.
         - instance: An instance of the type with all properties set to the default values that you want to have added to the data source.
     */
    public func registerTableSchema<T: ADDataTable>(_ type: T.Type, withDefaultValues instance: T = T.init()) throws {
        
        // Save a default instance to create the table in CloudKit
        do {
            try save(instance) { record, error in
                if let error = error {
                    Log.error(subsystem: "ADiCloudProvider", category: "registerTableSchema", "Registration Failed: \(error)")
                } else {
                    
                }
            }
        } catch {
            // Report error
            Log.error(subsystem: "ADiCloudProvider", category: "registerTableSchema", "Registration Failed: \(error)")
        }
    }
    
    /**
     Ensures that the key for a given table is unique inside the entire database by including the name of the table with the key unless the key is a GUID, since they are already unique.
     
     - Parameters:
         - type: The type of the class to generate a unique key for.
         - key: The value to generate a unique key from.
     - Returns: The new unique key for the record.
    */
    private func uniqueKey<T: ADDataTable>(_ type: T.Type, forPrimaryKeyValue key: Any) -> String {
        switch type.primaryKeyType {
        case .autoUUIDString:
            return "\(key)"
        default:
            return "\(type.tableName)\(key)"
        }
    }
    
    /**
     Saves the given class conforming to the `ADDataTable` protocol to the database. If the iCloud database does not contain a table named in the **tableName** property, one will be created first. If a record is not on file matching the **primaryKey** value a new record will be created, else an error will be thrown.
     
     ## Example:
     ```swift
     var category = Category()
     try ADiCloudProvider.shared.save(category)
     ```
     
     - Parameter value: The class instance to save to the database.
     - Parameter completionHandler: An optional handler to call after the save completes.
     */
    public func save<T: ADDataTable>(_ value: T, completionHandler:CloudKitRecordCompletionHandler? = nil) throws {
        let baseType = type(of: value)
        
        // Ensure the database is open
        guard isOpen else {
            throw ADDataProviderError.dataSourceNotOpen
        }
        
        // Try to encode record
        if var data = try ADSQLEncoder().encode(value) as? ADRecord {
            if var key = data[baseType.primaryKey] {
                // Has a key been specified?
                if isUndefined(key: key) {
                    if let newKey = makeID(baseType) {
                        key = newKey
                        data[baseType.primaryKey] = key
                    } else {
                        key = UUID().uuidString
                    }
                }
                
                // Load any existing `CKRecord` for this key or build a brand new record
                try fetchOrCreateCKRecord(value, forPrimaryKeyValue: key) { record, error in
                    do {
                        // Update record
                        let updateRecord = try self.updateCloudKitRecord(for: record, from: data)
                        
                        // Save updated record to iCloud
                        try self.save(updateRecord, tableName: baseType.tableName, completionHandler: completionHandler)
                    } catch {
                        if let handler = completionHandler {
                            // Pass info to caller.
                            handler(record, error)
                        } else {
                            // Report error
                            Log.error(subsystem: "ADiCloudProvider", category: "save", "Unable to save record to \(baseType.tableName): \(error)")
                        }
                    }
                }
                
            } else {
                throw ADDataProviderError.failedToPrepareSQL(message: "Unable locate required value for key \(baseType.primaryKey).")
            }
        } else {
            throw ADDataProviderError.failedToPrepareSQL(message: "Unable to convert class to a ADRecord.")
        }
        
    }
    
    
    /// Writes the given `CKRecord` to iCloud and reports success or failure to the optional completion handler.
    /// - Parameters:
    ///   - record: The `CKRecord` to save to iCloud.
    ///   - tableName: The name of the table the record is being saved to.
    ///   - completionHandler: An optional handler to call after the save completes.
    private func save(_ record:CKRecord, tableName:String, completionHandler: CloudKitRecordCompletionHandler? = nil) throws {
        
        // Attempt to save record to database.
        iCloudDatabase?.save(record) { record, error in
            if let handler = completionHandler {
                // Pass info to caller.
                handler(record, error)
            } else if let err = error {
                // Report error
                Log.error(subsystem: "ADiCloudProvider", category: "save", "Unable to save record to \(tableName): \(err)")
            }
        }
    }
    
    /**
     Either loads an existing `CKRecord` from iCloud or creates a new `CKRecord` if the record isn't found or cannot be loaded.
     
     ## Example:
     ```swift
     var category = Category()
     try ADiCloudProvider.shared.fetchOrCreateCKRecord(category, forPrimaryKeyValue: category.id) { record, error in
        ...
     }
     ```
     
     - Parameter value: The class instance to save to the database.
     - Parameter forPrimaryKeyValue: The primary key for the record.
     - Parameter completionHandler: Handles the `CKRecord` being loaded or created.
     */
    private func fetchOrCreateCKRecord<T: ADDataTable>(_ value: T, forPrimaryKeyValue key: Any, completionHandler:@escaping (CKRecord, Error?) -> Void) throws {
        let baseType = type(of: value)
        
        // Ensure the database is open
        guard isOpen else {
            throw ADDataProviderError.dataSourceNotOpen
        }
        
        // Assemble key
        let recordKey = CKRecord.ID(recordName: uniqueKey(baseType, forPrimaryKeyValue: key))
        
        // Attempt to read from database
        iCloudDatabase?.fetch(withRecordID: recordKey) { record, error in
            // Process returned data
            if let err = error {
                // Build new CloudKit record
                let newRecord = CKRecord(recordType: baseType.tableName, recordID: recordKey)
                
                // Return found record
                completionHandler(newRecord, err)
            } else if let record = record {
                // Return found record
                completionHandler(record, nil)
            } else {
                // Build new CloudKit record
                let newRecord = CKRecord(recordType: baseType.tableName, recordID: recordKey)
                
                // Return found record
                completionHandler(newRecord, ADSQLExecutionError.noRowsReturned(message: "Record not found for key \(key)."))
            }
        }
    }
    
    /**
     Updates the given class conforming to the `ADDataTable` protocol to the database. If the iCloud database does not contain a table named in the **tableName** property, one will be created first. If a record is not on file matching the **primaryKey** value an error will be thrown, else the existing record will be updated.
     
     ## Example:
     ```swift
     var category = Category()
     try ADSPONProvider.shared.update(category)
     ```
     
     - Parameter value: The class instance to update in the database.
     - Parameter completionHandler: An optional handler to call after the save completes.
     */
    @available(*, deprecated, message: "Call `save` directly as it handles updates correctly now.")
    public func update<T: ADDataTable>(_ value: T, completionHandler:CloudKitRecordCompletionHandler? = nil) throws {
        
        // Just call save now since I've updated it to handle updates automatically
        try save(value, completionHandler: completionHandler)
    }
    
    /**
     Removes the given record from the database.
     
     - Parameters:
         - value: The object to remove from the database.
         - completionHandler: The completion handler that gets called at the end of the deletion process.
    */
    public func delete<T: ADDataTable>(_ value: T, completionHandler:CloudKitRecordIDCompletionHandler? = nil) throws {
        let baseType = type(of: value)
        
        // Ensure the database is open
        guard isOpen else {
            throw ADDataProviderError.dataSourceNotOpen
        }
        
        // Try to encode record
        if let data = try ADSQLEncoder().encode(value) as? ADRecord {
            if let key = data[baseType.primaryKey] {
                // Is the key field blank?
                if isUndefined(key: key) {
                    if let handler = completionHandler {
                        // Return to caller.
                        handler(nil, nil)
                        return
                    } else {
                        // Consider this an error and throw
                        throw ADDataProviderError.failedToPrepareSQL(message: "Primary key was not defined for  \(baseType.primaryKey).")
                    }
                }
                
                // Assemble key
                let cloudkitKey = uniqueKey(baseType, forPrimaryKeyValue: key)
                let recordKey = CKRecord.ID(recordName: cloudkitKey)
                
                // Attempt to nuke record
                iCloudDatabase?.delete(withRecordID: recordKey) { recordID, error in
                    if let handler = completionHandler {
                        // Pass info to caller.
                        handler(recordID, error)
                    } else if let err = error {
                        // Report error
                        Log.error(subsystem: "ADiCloudProvider", category: "delete", "Unable to delete `\(cloudkitKey)` to \(baseType.tableName): \(err)")
                    }
                }
            } else {
                throw ADDataProviderError.failedToPrepareSQL(message: "Unable locate required value for key \(baseType.primaryKey).")
            }
        } else {
            throw ADDataProviderError.failedToPrepareSQL(message: "Unable to convert class to a ADRecord.")
        }
    }
    
    /**
     Deletes any record matching the given id from the database.
     
     - Parameters:
         - type: The type of record to delete.
         - key: The ID of the object to remove from the database.
         - completionHandler: The completion handler that gets called at the end of the deletion process.
    */
    public func delete<T: ADDataTable>(_ type: T.Type, forPrimaryKeyValue key: Any, completionHandler:CloudKitRecordIDCompletionHandler? = nil) throws {
        
        // Ensure the database is open
        guard isOpen else {
            throw ADDataProviderError.dataSourceNotOpen
        }
        
        // Assemble key
        let recordKey = CKRecord.ID(recordName: uniqueKey(type, forPrimaryKeyValue: key))
        
        // Attempt to nuke record
        iCloudDatabase?.delete(withRecordID: recordKey) { recordID, error in
            if let handler = completionHandler {
                // Pass info to caller.
                handler(recordID, error)
            } else if let err = error {
                // Report error
                Log.error(subsystem: "ADiCloudProvider", category: "delete", err.localizedDescription)
            }
        }
    }
    
    /**
     Loads an object of the given type with the given primary key value.
     
     - Parameters:
         - type: The type of object to return.
         - key: The primary ID of the object.
         - completionHandler: The completion handler that gets called during the object load.
    */
    public func loadRow<T: ADDataTable>(ofType type: T.Type, forPrimaryKeyValue key: Any, completionHandler:@escaping (T?, Error?) -> Void) throws {

        // Ensure the database is open
        guard isOpen else {
            throw ADDataProviderError.dataSourceNotOpen
        }
        
        // Assemble key
        let recordKey = CKRecord.ID(recordName: uniqueKey(type, forPrimaryKeyValue: key))
        
        // Attempt to read from database
        iCloudDatabase?.fetch(withRecordID: recordKey) { [weak self] record, error in
            // Process returned data
            if let err = error {
                // Encountered error, pass forward
                completionHandler(nil, err)
            } else if let record = record {
                do {
                    if let data = try self?.buildADRecord(from: record) {
                        let item = try ADSQLDecoder().decode(type, from: data)
                        completionHandler(item, nil)
                    }
                } catch {
                    // Encountered error, pass forward
                    completionHandler(nil, error)
                }
            } else {
                // Not found
                completionHandler(nil, ADSQLExecutionError.noRowsReturned(message: "Record not found for key \(key)."))
            }
        }
    }
    
    /**
     Loads any objects of the given type matching the given query. Use `loadRows` over `getRows` when you know a query will return a small number of records or if you don't want to limit the number of rows returned.
     
     - Parameters:
         - type: The type of object to return.
         - query: The query used to find the records. Send in "*" to return all rows.
         - sortBy: The field to sort the returned set on. If "" the rows will be unsorted.
         - sortAssending: The direction to sort by.
         - parameters: A list of parameters used in the query string.
         - completionHandler: The completion handler that gets called during the object load.
     - Remark: Use `%@` for value objects such as strings, numbers, and dates. Use `%K` for the name of a field. This substitution variable indicates that the substituted string should be used to look up a field name. See: https://developer.apple.com/documentation/cloudkit/ckquery
     */
    public func loadRows<T: ADDataTable>(ofType type: T.Type, matchingQuery query: String, sortBy:String = "", sortAssending:Bool = true, withParameters parameters: [Any]? = nil, completionHandler:@escaping ([T]?, Error?) -> Void) throws {
        
        // Ensure the database is open
        guard isOpen else {
            throw ADDataProviderError.dataSourceNotOpen
        }
        
        // Assemble search predicate
        var predicate = NSPredicate(value: true)
        if query != "*" {
            predicate = NSPredicate(format: query, argumentArray: parameters)
        }
        
        // Assemble query
        let iCloudQuery = CKQuery(recordType: type.tableName, predicate: predicate)
        
        // Has sort instruction?
        if !sortBy.isEmpty {
            // Yes, build and attach to query
            iCloudQuery.sortDescriptors = [
                NSSortDescriptor(key: sortBy, ascending: sortAssending)
            ]
        }
        
        // Attempt to query database
        iCloudDatabase?.fetch(withQuery: iCloudQuery, inZoneWith: nil) { results in
            switch results {
            case .success(let data):
                do {
                    var rows:[T] = []
                    
                    // Process all rows
                    let decoder = ADSQLDecoder()
                    for (_, recordResult) in data.matchResults {
                        switch recordResult {
                        case .success(let record):
                            let data = try self.buildADRecord(from: record)
                            let item = try decoder.decode(type, from: data)
                            rows.append(item)
                        case .failure(let error):
                            // Encountered error, pass forward
                            completionHandler(nil, error)
                        }
                    }
                    
                    // Return results
                    completionHandler(rows, nil)
                } catch {
                    // Encountered error, pass forward
                    completionHandler(nil, error)
                }
            case .failure(let error):
                // Encountered error, pass forward
                completionHandler(nil, error)
            }
        }
    }
    
    /**
     Loads any objects of the given type matching the given query up to the given limit. Use `getRows` over `loadRows` when the resulting dataset returned could be larger than the maximum number of records that CloudKit will return in a single query or if you wish to limit the number of rows returned. See: https://www.hackingwithswift.com/read/33/6/reading-from-icloud-with-cloudkit-ckqueryoperation-and-nspredicate
     
     - Parameters:
         - type: The type of object to return.
         - query: The query used to find the records. Send in "*" to return all rows.
         - parameters: A list of parameters used in the query string.
         - limit: The maximum number of rows to return. The default is the maximum number of rows that CloudKit will return.
         - completionHandler: The completion handler that gets called during the object load.
     - Remark: Use `%@` for value objects such as strings, numbers, and dates. Use `%K` for the name of a field. This substitution variable indicates that the substituted string should be used to look up a field name.
    */
    public func getRows<T: ADDataTable>(ofType type: T.Type, matchingQuery query: String, withParameters parameters: [Any]? = nil, limit:Int = CKQueryOperation.maximumResults, completionHandler:@escaping ([T]?, Error?) -> Void) throws {
        
        // Ensure the database is open
        guard isOpen else {
            throw ADDataProviderError.dataSourceNotOpen
        }
        
        // Clear continuation cursor
        continuationCursor = nil
        
        // Create storage for the returned records
        var rows:[T] = []
        let decoder = ADSQLDecoder()
        
        // Assemble search predicate
        var predicate = NSPredicate(value: true)
        if query != "*" {
            predicate = NSPredicate(format: query, argumentArray: parameters)
        }
        
        // Assemble query
        let iCloudQuery = CKQuery(recordType: type.tableName, predicate: predicate)
        
        // Assemble query operation
        let operation = CKQueryOperation(query: iCloudQuery)
        operation.resultsLimit = limit
        continuationLimit = limit
        
        // Handle a record being returned
        operation.recordMatchedBlock = { [weak self] recordId, results in
            switch results {
            case .failure(let error):
                Log.error(subsystem: "ADiCloudProvider", category: "getRows", "Error decoding CKRecord: \(error)")
            case .success(let record):
                do {
                    if let data = try self?.buildADRecord(from: record) {
                        let item = try decoder.decode(type, from: data)
                        rows.append(item)
                    }
                } catch {
                    Log.error(subsystem: "ADiCloudProvider", category: "getRows", "Error decoding CKRecord: \(error)")
                }
            }
        }
        
        // Handle the query completing
        operation.queryResultBlock = {[weak self] results in
            switch results {
            case .failure(let error):
                // Pass error on to handler
                completionHandler(nil, error)
            case .success(let cursor):
                // Save continuation cursor
                self?.continuationCursor = cursor
                
                // Pass retrieved data back to caller
                completionHandler(rows, nil)
            }
        }
        
        // Execute the query
        iCloudDatabase?.add(operation)
    }
    
    /**
     After performing a `getRows` call, if the `hasMoreRows` property is `true` use this function to return the remaining rows.
     
     - Parameters:
         - type: The type of object to return.
         - completionHandler: The completion handler that gets called during the object load.
     
     - Remark: If the `hasMoreRows` property is still `true` after calling this function, there were still more rows than could be returned in a single call. You can continue to call `getRemainingRows` until `hasMoreRows` is `false` to retrieve all records.
    */
    public func getRemainingRows<T: ADDataTable>(ofType type: T.Type, completionHandler:@escaping ([T]?, Error?) -> Void) throws {
        
        // Ensure the database is open
        guard isOpen else {
            throw ADDataProviderError.dataSourceNotOpen
        }
        
        // Ensure more rows are remaining to load.
        guard hasMoreRows else {
            throw ADDataProviderError.noRowsRemaining
        }
        
        // Create storage for the returned records
        var rows:[T] = []
        let decoder = ADSQLDecoder()
        
        // Assemble query operation
        let operation = CKQueryOperation(cursor: continuationCursor!)
        operation.resultsLimit = continuationLimit
        
        // Handle a record being returned
        operation.recordMatchedBlock = { [weak self] recordId, results in
            switch results {
            case .failure(let error):
                Log.error(subsystem: "ADiCloudProvider", category: "getRemainingRows", "Error decoding CKRecord: \(error)")
            case .success(let record):
                do {
                    if let data = try self?.buildADRecord(from: record) {
                        let item = try decoder.decode(type, from: data)
                        rows.append(item)
                    }
                } catch {
                    Log.error(subsystem: "ADiCloudProvider", category: "getRemainingRows", "Error decoding CKRecord: \(error)")
                }
            }
        }
        
        // Handle the query completing
        operation.queryResultBlock = {[weak self] results in
            switch results {
            case .failure(let error):
                // Pass error on to handler
                completionHandler(nil, error)
            case .success(let cursor):
                // Save continuation cursor
                self?.continuationCursor = cursor
                
                // Pass retrieved data back to caller
                completionHandler(rows, nil)
            }
        }
        
        
        // Execute the query
        iCloudDatabase?.add(operation)
    }
}
