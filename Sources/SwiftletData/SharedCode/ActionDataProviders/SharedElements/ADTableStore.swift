//
//  ADDataTable.swift
//  ActionControls
//
//  Created by Kevin Mullins on 11/9/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/**
 Represents an in-memory SQL Data Store table used to hold both the table's schema and the data it represents.
 
  - Remark: Since a `ADTableStore` holds all data in-memory, care should be taken not to overload memory. As a result, an `ADTableStore` is not a good choice for working with large amounts of data.
 */
public class ADTableStore {
    
    // MARK: - Properties
    /// Holds the schema defining this table as the columns for each row, the column types and any constraints applied to those columns.
    public var schema: ADTableSchema!
    
    /// Returns the value of the primary key for the last record added to the table. If there are no records in the table or no primary key defined, `nil` is returned.
    public var lastPrimaryKeyValue: Any? {
        // Any records
        if rows.count < 1 {
            return nil
        }
        
        // Any primary key
        let key = schema.primaryKey
        if key.isEmpty {
            return nil
        }
        
        // Get last value
        let record = rows[rows.count - 1]
        return record[key]
    }
    
    /// Returns the next ID value for auto incrementing integer primary keys else returns zero (0).
    public var nextAutoIncrementingID: Int {
        // Has primary key?
        let key = schema.primaryKey
        if key.isEmpty {
            return 0
        }
        
        // Get column
        let column = schema.primaryKeyColumn!
        
        // Is the type Integer?
        if column.type != .integerType {
            return 0
        }
        
        // Auto incrementing key?
        if !column.autoIncrement {
            return 0
        }
        
        // Increment last number
        if let id = lastPrimaryKeyValue as? Int {
            return (id + 1)
        } else {
            return rows.count
        }
    }
    
    /// For data sources that provide in-memory data storage (such as JSON, SPON and XML) this property holds all of the rows in the table as `ADRecord` objects.
    public var rows: ADRecordSet = []
    
    // MARK: - Initializers
    /**
     Initializes a new table storage instance.
     
     - Parameter tableName: The name of the table to be stored in the instance.
    */
    public init(tableName: String) {
        self.schema = ADTableSchema(name: tableName)
    }
    
    /**
     Initializes a new table storage instance.
     - Parameter dictionary: A `ADInstanceDictionary` to initialize the table storage from.
    */
    public init(fromInstance dictionary: ADInstanceDictionary) {
        self.decode(fromInstance: dictionary)
    }
    
    // MARK: - Functions
    /**
     Test to see if the table contains a row with the given primary key value.
     
     - Parameter withPrimaryKeyValue: The value to find in the table.
     - Returns: `true` if the table contains a row with the given primary key value, else `false` if not.
    */
    public func hasRow(withPrimaryKeyValue value: Any) -> Bool {
        let key = schema.primaryKey
        
        // Has a primary key been defined?
        if key.isEmpty {
            return false
        }
        
        // Scan all records
        for row in rows {
            if let id = row[key] {
                if ADUtilities.compare(id, .equalTo, value) {
                    // Found
                    return true
                }
            }
        }
        
        // Not found
        return false
    }
    
    /**
     Attempts to insert the given record in the table.
     
     - Parameters:
         - record: The `ADRecord` to add to the table.
         - action: The `ADSQLInsertInstruction.Action` to use when the insert fails. The default is `insert` only.
    */
    public func insertRow(_ record: ADRecord, action: ADSQLInsertInstruction.Action = .insert) throws {
        
        var record = record
        
        // Does the record have the correct number of values?
        if record.count != schema.column.count {
            throw ADSQLExecutionError.invalidRecord(message: "The number of columns in the provided record don't match the number of columns in the table.")
        }
        
        // Does the table contain all of the columns in the record?
        for col in record.keys {
            if !schema.hasColumn(named: col) {
                throw ADSQLExecutionError.unknownColumn(message: "Table `\(schema.name)` does not contain column `\(col)`.")
            }
        }
        
        // Does the table have a primary key?
        let key = schema.primaryKey
        if !key.isEmpty {
            // Grab primary key column
            let column = schema.primaryKeyColumn!
            
            // Auto incrementing integer?
            if column.type == .integerType && column.isPrimaryKey && column.autoIncrement {
                // Yes, automatically assign value from table
                record[column.name] = nextAutoIncrementingID
            }
            
            // Does the key have to be unique?
            if column.isKeyUnique {
                let id = record[key]!
                // Yes, is the key already on file?
                if hasRow(withPrimaryKeyValue: id) {
                    switch action {
                    case .replace, .insertOrReplace:
                        // TODO: call update from here
                        break
                    case .insertOrRollback, .insertOrAbort, .insertOrIgnore:
                        // Do nothing on duplicate value
                        return
                    default:
                        throw ADSQLExecutionError.duplicateRecord(message: "Table `\(schema.name)` alread contains a record with a primary key value of `\(id)`")
                    }
                }
            }
        }
        
        // Does any column have a check expression?
        for col in schema.column {
            if let check = col.checkExpression {
                if let result = try check.evaluate(forRecord: record) {
                    if let valid = result as? Bool {
                        // Passes check?
                        if !valid {
                            throw ADSQLExecutionError.failedCheckConstraint(message: "Record fails the CHECK constraint for column `\(col.name)`, unable to insert.")
                        }
                    } else {
                        throw ADSQLExecutionError.syntaxError(message: "CHECK constraint on column `\(col.name)` should return a boolean value but returned `\(result)` instead.")
                    }
                }
            }
        }
        
        // Add record to collection
        rows.append(record)
    }
    
    /**
     Checks the given record to ensure it is valid in the context of the table.
     - Parameter record: The `ADRecord` to validate.
     - Returns: `nil` if there were no issues with the record, else returns a `ADSQLExecutionError` describing any found issues.
    */
    public func validateRecord(_ record: ADRecord) -> ADSQLExecutionError? {
        
        // Does any column have a check expression?
        for col in schema.column {
            if let check = col.checkExpression {
                do {
                    if let result = try check.evaluate(forRecord: record) {
                        if let valid = result as? Bool {
                            // Passes check?
                            if !valid {
                                return ADSQLExecutionError.failedCheckConstraint(message: "Record fails the CHECK constraint for column `\(col.name)`, unable to insert.")
                            }
                        } else {
                            return ADSQLExecutionError.syntaxError(message: "CHECK constraint on column `\(col.name)` should return a boolean value but returned `\(result)` instead.")
                        }
                    }
                } catch {
                    return error as? ADSQLExecutionError
                }
            }
        }
        
        // No issues
        return nil
    }
    
    /**
     Returns the first row matching the given record on the given list of columns.
     
     - Parameters:
         - record: An `ADRecord` containing the values to match against.
         - columnNames: An array of columns names to match on.
     - Returns: An `ADRecord` representing the first row matched in the table or `nil` if none was found.
    */
    public func findRow(matching record: ADRecord, onColumns columnNames: [String]) -> ADRecord? {
        
        // Scan for matchin row in table
        for row in rows {
            var found = true
            
            // See if all provided columns match
            for column in columnNames {
                if let v1 = row[column] {
                    if let v2 = record[column] {
                        found = found && ADUtilities.compare(v1, .equalTo, v2)
                    } else {
                        found = false
                    }
                } else {
                    found = false
                }
            }
            
            // Found match?
            if found {
                // Yes, return it to caller
                return row
            }
        }
        
        // Not found
        return nil
    }
    
    /**
     Returns all rows matching the given record on the given list of columns.
     
     - Parameters:
         - record: An `ADRecord` containing the values to match against.
         - columnNames: An array of columns names to match on.
     - Returns: An `ADRecordSet` representing the all rows matched in the table or an empty set if none were found.
     */
    public func findRows(matching record: ADRecord, onColumns columnNames: [String]) -> ADRecordSet {
        var records: ADRecordSet = []
        
        // Scan for matchin row in table
        for row in rows {
            var found = true
            
            // See if all provided columns match
            for column in columnNames {
                if let v1 = row[column] {
                    if let v2 = record[column] {
                        found = found && ADUtilities.compare(v1, .equalTo, v2)
                    } else {
                        found = false
                    }
                } else {
                    found = false
                }
            }
            
            // Found match?
            if found {
                // Yes, accumulate
                records.append(row)
            }
        }
        
        // Return results
        return records
    }
    
    /**
     Returns the first row matching the values in the given record using the given expression.
     
     - Parameters:
         - record: An `ADRecord` containing the values to match against.
         - expression: A `ADSQLExpression` used to compare rows in the table against the passed in record's values.
         - alias: An option alias for the table's name.
     - Returns: An `ADRecord` representing the first row matched or `nil` if none was found.
    */
    public func findRow(matching record: ADRecord, on expression: ADSQLExpression, alias: String = "") throws -> ADRecord? {
        
        // Scan for matching row in table
        for row in rows {
            // Build test record
            var testRecord = record
            for (col, val) in row {
                let id = "\(alias.isEmpty ? schema.name : alias).\(col)"
                testRecord[id] = val
            }
            
            // Process the expression
            if let evaluation = try expression.evaluate(forRecord: testRecord) {
                if let valid = evaluation as? Bool {
                    if valid {
                        // Found match
                        return row
                    }
                } else {
                    throw ADSQLExecutionError.syntaxError(message: "ON clause should evaluate to a boolean value but returned `\(evaluation)` instead.")
                }
            }
        }
        
        // Not found
        return nil
    }
    
    /**
     Returns the all rows matching the values in the given record using the given expression.
     
     - Parameters:
         - record: An `ADRecord` containing the values to match against.
         - expression: A `ADSQLExpression` used to compare rows in the table against the passed in record's values.
         - alias: An option alias for the table's name.
     - Returns: An `ADRecordSet` representing the all rows matched or an empty set if none were found.
     */
    public func findRows(matching record: ADRecord, on expression: ADSQLExpression, alias: String = "") throws -> ADRecordSet {
        var records: ADRecordSet = []
        
        // Scan for matching row in table
        for row in rows {
            // Build test record
            var testRecord = record
            for (col, val) in row {
                let id = "\(alias.isEmpty ? schema.name : alias).\(col)"
                testRecord[id] = val
            }
            
            // Process the expression
            if let evaluation = try expression.evaluate(forRecord: testRecord) {
                if let valid = evaluation as? Bool {
                    if valid {
                        // Found match
                        records.append(row)
                    }
                } else {
                    throw ADSQLExecutionError.syntaxError(message: "ON clause should evaluate to a boolean value but returned `\(evaluation)` instead.")
                }
            }
        }
        
        // Return results
        return records
    }
    
    /**
     Encodes the table store into an Instance Dictionary for storage in a Swift Portable Object Notation (SPON) format.
     -Returns: The table store represented as an Instance Dictionary.
     */
    public func encode() -> ADInstanceDictionary {
        let dictionary = ADInstanceDictionary()
        
        // Build array of data
        let array = ADInstanceArray()
        for row in rows {
            let dict = ADInstanceDictionary()
            dict.storage = row
            array.storage.append(dict)
        }
        
        // Save values
        dictionary.typeName = "Table"
        dictionary.storage["schema"] = schema.encode()
        dictionary.storage["rows"] = array.encode()
        
        return dictionary
    }
    
    /**
     Decodes the table store from an Instance Dictionary that has been read from a Swift Portable Object Notation (SPON) stream.
     - Parameter dictionary: A `ADInstanceDictionary` representing the values for the table store.
     */
    public func decode(fromInstance dictionary: ADInstanceDictionary) {
        if let value = dictionary.storage["schema"] as? ADInstanceDictionary {
            schema = ADTableSchema(fromInstance: value)
        }
        if let array = dictionary.storage["rows"] as? ADInstanceArray {
            for item in array.storage {
                if let value = item as? ADInstanceDictionary {
                    rows.append(value.storage)
                }
            }
        }
    }
}
