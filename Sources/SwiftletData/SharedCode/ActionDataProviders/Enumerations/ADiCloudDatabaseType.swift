//
//  ADiCloudDatabaseType.swift
//  ActionData iOS
//
//  Created by Kevin Mullins on 3/4/19.
//

import Foundation

/// Holds the type of database that an instance of the `ADiCloudProvider` will access.
public enum ADiCloudDatabaseType {
    /// The database containing the user’s private data.
    case privateDatabase
    
    /// The database containing the data shared by all users.
    case publicDatabase
    
    /// The database containing shared user data.
    case sharedDatabase
}
