//
//  ADRecord.swift
//  ActionControls
//
//  Created by Kevin Mullins on 9/13/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/**
 A class conforming to this protocol defines a unique container that holds the data that can be read from or written to a `ADDataProvider` source. For example, a `ADDataTable` can be used represent a SQLite database table, a JSON node or a XML node.
 
 Besides acting as a model for the physical representation of the data within the given data source (as defined by a `ADDataProvider`), an instance of a class conforming to this protocol will act as an individual "row" of data stored within the data source.
 
 ## Example:
 ```swift
 import Foundation
 import ActionUtilities
 import ActionData
 
 class Category: ADDataTable {
 
     enum CategoryType: String, Codable {
         case local
         case web
     }
 
     // Provides conformance to `ADDataTable` and provides the name
     // of the table, the name of the primary key and the type of
     // primary key.
     static var tableName = "Categories"
     static var primaryKey = "id"
     static var primaryKeyType: ADDataTableKeyType = .computedInt
 
     var id = 0
     var added = Date()
     var name = ""
     var description = ""
     var enabled = true
     var highlightColor = UIColor.white.toHex()
     var type: CategoryType = .local
     var icon: Data = UIImage().toData()
 
     required init() {
 
     }
 }
 ```
 
 - Warning: A class or struct conforming to this protocol **must** contain a property with the same name as the `primaryKey` value. Failing to do so will result in an error.
 */
public protocol ADDataTable: Codable {
    
    // MARK: - Class Properties
    /// Gets the name of the table that the data is stored in.
    static var tableName: String { get }
    
    /// Returns the key for the table property that acts as the record's primary key. Typically this defaults to a field called `id`.
    /// - Warning: A class or struct conforming to this protocol **must** contain a property with the same name as the `primaryKey` value. Failing to do so will result in an error.
    static var primaryKey: String { get }
    
    /// Returns the type of primary key. Typically, the default type is `uniqueValue`.
    static var primaryKeyType: ADDataTableKeyType { get }
    
    /// Initializes a new instance of the `ADDataTable`.
    init() 
}
