//
//  ADDataTableKeyType.swift
//  ActionControls
//
//  Created by Kevin Mullins on 9/14/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/**
 Defines the type of primary key that has been specified for a class conforming to the `ADDataTable` protocol.
 */
public enum ADDataTableKeyType {
    /// Specifies that the given primary key must be unique and not already exist for any other key in the data provider's data source.
    case uniqueValue
    
    /// For an `Int` type of primary key, automatically assign a key value when a new row is added to the data provider's data source.
    /// - Remarks: For SQL based data providers, the ID is typically generated using the AUTOINCREMENT key type.
    case autoIncrementingInt
    
    /// For an `Int` type of primary key, automatically assign a key value when a new row is added to the data provider's data source by finding the largest used ID number and adding one to it.
    /// - Remarks: This key type is provided as a workaround to issues with the SQLite database's AUTOINCREMENT implementation and to provide a valid ID to a record when it is first created (instead of after its been saved) for parent-child table relationships.
    case computedInt
    
    /// For a `String` type of primary key, automatically assign a UUID as the key value when a new class conforming to the `ADDataTable` protocol is created.
    case autoUUIDString
}
