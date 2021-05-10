//
//  ADSQLForeignKeyExpression.swift
//  ActionControls
//
//  Created by Kevin Mullins on 10/26/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/// Defines a foreign key expression used in a SQL statement.
public class ADSQLForeignKeyExpression: ADSQLExpression {
    
    // MARK: - Enumerations
    /// Defines the modify action to take.
    public enum OnModify: String {
        /// Ignore the key if modified.
        case ignore
        
        /// Delete the foreign value if deleting a row with the key.
        case delete
        
        /// Update the foreign value if update a row with the key.
        case update
    }
    
    /// Defines the action to take on the foreign key.
    public enum ModifyAction: String {
        /// Set the key to null.
        case setNull
        
        /// Set the key to the default value.
        case setDefault
        
        /// Cascade changes to the foreign key's table.
        case cascade
        
        /// Restrict changes to the foreign key.
        case restrict
        
        /// Take no action.
        case noAction
    }
    
    // MARK: - Properties
    /// The name of the foreign key table.
    public var foreignTableName: String = ""
    
    /// A list of columns that compose the key.
    public var columnNames: [String] = []
    
    /// The action to take when the foreign key is modified when the parent row is modified.
    public var onModify = OnModify.ignore
    
    /// The action to take when modifying a foreign key value.
    public var modifyAction = ModifyAction.noAction
    
    /// The name of the field to match in the foreign key table.
    public var matchName: String = ""
    
    /// If `true`, the action is defferable, else `false`.
    public var deferrable = false
    
    /// If `true`, the action is immediate, else `false`.
    public var initiallyImmediate = true
    
    // MARK: - Initializers
    /// Creates a new Foreign Key Expression instance.
    public init() {
        
    }
    
    /**
     Decodes the expression from an Instance Dictionary that has been read from a Swift Portable Object Notation (SPON) stream.
     - Parameter dictionary: A `ADInstanceDictionary` representing the values for the expression.
     */
    public required init(fromInstance dictionary: ADInstanceDictionary) {
        self.decode(fromInstance: dictionary)
    }
    
    // MARK: - Functions
    /**
     Evaluates the given expression and returns a result based on the data in the record passed in.
     - Parameter row: A `ADRecord` containing values to be evaluated against the expression.
     - Returns: The result of the evaluation.
     */
    @discardableResult public func evaluate(forRecord row: ADRecord? = nil) throws -> Any? {
        // TODO: Process a foreign key expression
        return nil
    }
    
    /**
     Encodes the expression into an Instance Dictionary for storage in a Swift Portable Object Notation (SPON) format.
     -Returns: The expression represented as an Instance Dictionary.
     */
    public func encode() -> ADInstanceDictionary {
        let dictionary = ADInstanceDictionary()
        let array = ADInstanceArray()
        
        // Save parameters into the array
        for item in columnNames {
            let exp = ADSQLLiteralExpression(value: item)
            array.storage.append(exp.encode())
        }
        
        // Save values
        dictionary.typeName = "ForeignKey"
        dictionary.storage["foreignTableName"] = foreignTableName
        dictionary.storage["columnNames"] = array
        dictionary.storage["onModify"] = onModify.rawValue
        dictionary.storage["modifyAction"] = modifyAction.rawValue
        dictionary.storage["matchName"] = matchName
        dictionary.storage["deferrable"] = deferrable
        dictionary.storage["initiallyImmediate"] = initiallyImmediate
        
        return dictionary
    }
    
    /**
     Decodes the expression from an Instance Dictionary that has been read from a Swift Portable Object Notation (SPON) stream.
     - Parameter dictionary: A `ADInstanceDictionary` representing the values for the expression.
     */
    public func decode(fromInstance dictionary: ADInstanceDictionary) {
        if let value = dictionary.storage["foreignTableName"] as? String {
            foreignTableName = value
        }
        if let array = dictionary.storage["columnNames"] as? ADInstanceArray {
            for item in array.storage {
                if let exp = item as? ADInstanceDictionary {
                    if let expression = ADSQLExpressionBuilder.build(fromInstance: exp) as? ADSQLLiteralExpression {
                        columnNames.append(expression.value)
                    }
                }
            }
        }
        if let value = dictionary.storage["onMofidy"] as? String {
            onModify = OnModify(rawValue: value)!
        }
        if let value = dictionary.storage["modifyAction"] as? String {
            modifyAction = ModifyAction(rawValue: value)!
        }
        if let value = dictionary.storage["matchName"] as? String {
            matchName = value
        }
        if let value = dictionary.storage["deferrable"] as? Bool {
            deferrable = value
        }
        if let value = dictionary.storage["initiallyImmediate"] as? Bool {
            initiallyImmediate = value
        }
    }
}
