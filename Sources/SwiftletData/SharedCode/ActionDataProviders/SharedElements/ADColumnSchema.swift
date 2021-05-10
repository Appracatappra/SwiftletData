//
//  ADColumnInfo.swift
//  ActionControls
//
//  Created by Kevin Mullins on 10/2/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/**
 Holds all of the schema information about a table schema's columns as read from a backing data store.
 */
open class ADColumnSchema {
    
    // MARK: - Properties
    /// The column's unique id.
    public var id = 0
    
    /// The column's name.
    public var name = ""
    
    /// The type of the columns sych as `TEXT`, `BOOLEAN`, `DATE`, etc.
    public var type = ADSQLColumnType.noneType
    
    /// `true` if the value of this column can be `null`, else `false`.
    public var allowsNull = true
    
    /// The default value for this column if no value is provided during an `INSERT` or `UPDATE` operation.
    public var defaultValue: Any?
    
    /// `true` if this column is the table's primary key.
    public var isPrimaryKey = false
    
    /// `true` if the key value must be unique, else `false`.
    public var isKeyUnique = true
    
    /// If the column is a PRIMARY KEY of the INTEGER type, is it automatically incremented when a new row is created in the table.
    public var autoIncrement: Bool = false
    
    /// Holds the expression for a Check constraint.
    public var checkExpression: ADSQLExpression?
    
    // MARK: - Initializers
    /**
     Initializes a new `ADColumnSchema` and sets its initial properties.
     - Parameter dictionary: A `ADInstanceDictionary` that defines the column.
    */
    public init(fromInstance dictionary: ADInstanceDictionary) {
        self.decode(fromInstance: dictionary)
    }
    
    /**
     Initializes a new `ADColumnSchema` and sets its initial properties.
     - Parameters:
         - id: The numeric id of the column.
         - name: The name of the column.
         - type: The type of data stored in the column.
    */
    public init(id: Int, name: String, type: ADSQLColumnType) {
        self.id = id
        self.name = name
        self.type = type
    }
    
    /**
     Initializes a new `ADColumnSchema` and sets its initial properties.
     - Parameters:
         - id: The unique id of the column.
         - name: The column name.
         - allowsNull: `true` if the column value can be `nil`, else `false`.
         - isPrimaryKey: `true` if this column is the primary key, else `false`.
         - defaultValue: The default value for the column.
         - isKeyUnique: `true` if the key value must be unique, else `false`.
    */
    public init(id: Any?, name: Any?, type: Any?, allowsNull: Any? = true, isPrimaryKey: Any? = false, defaultValue: Any? = nil, isKeyUnique: Bool = true) {
        self.id = id as! Int
        self.name = name as! String
        self.type.set(fromString:type as! String)
        self.defaultValue = defaultValue
        self.allowsNull = decodeBool(allowsNull)
        self.isPrimaryKey = decodeBool(isPrimaryKey)
        self.isKeyUnique = isKeyUnique
    }
    
    // MARK: - Functions
    /**
     Takes a raw boolean value read from a data source schema and returns it as a Swift `Bool`.
     
     - Parameter value: The value to convert to a Swift `Bool`.
     - Returns: The Swift `Bool` value or `false` if unable to convert.
     */
    private func decodeBool(_ value: Any?) -> Bool {
        if value == nil {
            return false
        } else if let bool = value as? Bool {
            return bool
        } else if let int = value as? Int {
            return (int == 1)
        } else if let text = value as? String {
            return (text == "true") || (text == "on") || (text == "yes")
        }
        
        // Default value
        return false
    }
    
    /**
     Encodes the column schema into an Instance Dictionary for storage in a Swift Portable Object Notation (SPON) format.
     -Returns: The column schema represented as an Instance Dictionary.
     */
    public func encode() -> ADInstanceDictionary {
        let dictionary = ADInstanceDictionary()
        
        // Save values
        dictionary.typeName = "ColumnSchema"
        dictionary.storage["id"] = id
        dictionary.storage["name"] = name
        dictionary.storage["type"] = type.rawValue
        dictionary.storage["allowsNull"] = allowsNull
        if let value = defaultValue {
            dictionary.storage["defaultValue"] = value
        }
        dictionary.storage["isPrimaryKey"] = isPrimaryKey
        dictionary.storage["isKeyUnique"] = isKeyUnique
        dictionary.storage["autoIncrement"] = autoIncrement
        if let check = checkExpression {
            dictionary.storage["check"] = check.encode()
        }
        
        return dictionary
    }
    
    /**
     Decodes the column schema from an Instance Dictionary that has been read from a Swift Portable Object Notation (SPON) stream.
     - Parameter dictionary: A `ADInstanceDictionary` representing the values for the column Schema.
     */
    public func decode(fromInstance dictionary: ADInstanceDictionary) {
        id = dictionary.storage["id"] as! Int
        name = dictionary.storage["name"] as! String
        if let value = dictionary.storage["type"] as? String {
            type = ADSQLColumnType(rawValue: value)!
        }
        allowsNull = dictionary.storage["allowsNull"] as! Bool
        if dictionary.storage.keys.contains("defaultValue") {
            defaultValue = dictionary.storage["defaultValue"]
        }
        isPrimaryKey = dictionary.storage["isPrimaryKey"] as! Bool
        isKeyUnique = dictionary.storage["isKeyUnique"] as! Bool
        autoIncrement = dictionary.storage["autoIncrement"] as! Bool
        if dictionary.storage.keys.contains("check") {
            if let value = dictionary.storage["check"] as? ADInstanceDictionary {
                checkExpression = ADSQLExpressionBuilder.build(fromInstance: value)
            }
        }
    }

}
