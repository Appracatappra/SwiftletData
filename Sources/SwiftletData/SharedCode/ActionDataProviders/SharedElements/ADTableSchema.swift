//
//  ADTableSchema.swift
//  ActionControls
//
//  Created by Kevin Mullins on 10/2/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/**
 Holds all the information about a table's schema as read from a backing data store.
 */
open class ADTableSchema {
    
    // MARK: - Properties
    /// The table name.
    public var name = ""
    
    /// The table's column information as an array of `ADColumnSchema` instances.
    public var column: [ADColumnSchema] = []
    
    /// Returns the column that has been defined as the primary key
    public var primaryKeyColumn: ADColumnSchema? {
        // Find primary key
        for col in column {
            if col.isPrimaryKey {
                return col
            }
        }
        
        // Not found
        return nil
    }
    
    /// Returns the primary key for the table or an empty string ("") if no primary key has been defined.
    public var primaryKey: String {
        // Find primary key
        for col in column {
            if col.isPrimaryKey {
                return col.name
            }
        }
        
        // Not found
        return ""
    }
    
    // MARK: - Initializers
    /**
     Creates a new instance of the table schema.
     
     - Parameter name: The name of the table
     */
    public init(name: String) {
        self.name = name
    }
    
    /**
     Initializes a new `ADTableSchema` and sets its initial properties.
     - Parameter dictionary: A `ADInstanceDictionary` to initialize the schema from.
    */
    public init(fromInstance dictionary: ADInstanceDictionary) {
        self.decode(fromInstance: dictionary)
    }
    
    // MARK: - Functions
    /**
     Adds the given column schema to the table's collection of columns.
     
     - Parameter value: The `ADColumnSchema` to add to the collection.
     */
    public func add(value: ADColumnSchema) {
        column.append(value)
    }
    
    /**
     Checks to see if the table contains a column with the given name.
     
     - Parameter named: The name of the column to check for.
     - Returns: `true` if the table contains the column else returns `false`.
    */
    public func hasColumn(named: String) -> Bool {
        
        // Scan all columns
        for col in column {
            if col.name == named {
                return true
            }
        }
        
        // Not found
        return false
    }
    
    /**
     Encodes the table schema into an Instance Dictionary for storage in a Swift Portable Object Notation (SPON) format.
     - Returns: The table schema represented as an Instance Dictionary.
     */
    public func encode() -> ADInstanceDictionary {
        let dictionary = ADInstanceDictionary()
        
        // Build array
        let array = ADInstanceArray()
        for col in column {
            array.storage.append(col.encode())
        }
        
        // Save values
        dictionary.typeName = "TableSchema"
        dictionary.storage["name"] = name
        dictionary.storage["columns"] = array
        
        return dictionary
    }
    
    /**
     Decodes the table schema from an Instance Dictionary that has been read from a Swift Portable Object Notation (SPON) stream.
     - Parameter dictionary: A `ADInstanceDictionary` representing the values for the table schema.
     */
    public func decode(fromInstance dictionary: ADInstanceDictionary) {
        name = dictionary.storage["name"] as! String
        if let array = dictionary.storage["columns"] as? ADInstanceArray {
            for item in array.storage {
                if let value = item as? ADInstanceDictionary {
                    column.append(ADColumnSchema(fromInstance: value))
                }
            }
        }
    }
}
