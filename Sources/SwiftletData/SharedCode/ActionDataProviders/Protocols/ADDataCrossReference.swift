//
//  ADDataCrossReference.swift
//  ActionControls
//
//  Created by Kevin Mullins on 10/11/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/**
 A class or struct conforming to this protocol can be used to store a one-to-many or many-to-many relationship between `ADDataTable` records stored in or read from a `ADDataProvider` instance.
 
 ## Example:
 ```swift
 import Foundation
 import ActionUtilities
 import ActionData
 
 struct Address: Codable {
     var addr1 = ""
     var addr2 = ""
     var city = ""
     var state = ""
     var zip = ""
 }
 
 class Person: ADDataTable {
 
     static var tableName = "People"
     static var primaryKey = "id"
     static var primaryKeyType = ADDataTableKeyType.autoUUIDString
 
     var id = UUID().uuidString
     var firstName = ""
     var lastName = ""
     var addresses: [String:Address] = [:]
 
     required init() {
 
     }
 
     init(firstName: String, lastName:String, addresses: [String:Address] = [:]) {
         self.firstName = firstName
         self.lastName = lastName
         self.addresses = addresses
     }
 }
 
 class Group: ADDataTable {
 
     static var tableName = "Groups"
     static var primaryKey = "id"
     static var primaryKeyType = ADDataTableKeyType.autoUUIDString
 
     var id = UUID().uuidString
     var name = ""
     var people = ADCrossReference<Person>(name: "PeopleInGroup", leftKeyName: "groupID", rightKeyName: "personID")
 
     required init() {
 
     }
 
     init(name: String, people: [Person] = []) {
         self.name = name
         self.people.storage = people
     }
 }
 ```
 */
public protocol ADDataCrossReference: Codable {
    
    // MARK: - Properties
    /// The name of the cross reference table.
    var crossReferenceName: String {get set}
    
    /// The name of the left-side key used to store the primary key of the `ADDataTable` on the left side of the relationship.
    var leftKeyName: String {get set}
    
    /// The name of the right-side key used to store the primary key of the `ADDataTable` on the right side of the relationship.
    var rightKeyName: String {get set}
    
    // MARK: - Functions
    /**
     Removes all cross references for the given key value from the given data provider.
     
     - Parameters:
         - provider: The `ADDataProvider` to remove the cross references from.
         - key: The left-side key value to delete the values for.
     */
    func delete(from provider: ADDataProvider, forKeyValue key:Any) throws
    
    /**
     Saves the given cross references to the data provider for the give key value. The cross reference table will automatically be created if it doesn't already exist.
     
     - Parameters:
         - provider: The provider to save values to the data source.
         - leftKey: The left-side key value to create the cross reference on.
     */
    func save(to provider: ADDataProvider, forKeyValue leftKey: Any) throws
    
    /**
     Loads all cross referenced `ADDataTable` instances for the given cross reference based on the given key value.
     
     - Parameters:
         - provider: The `ADDataProvider` to load the `ADDataTable` instances from.
         - key: The left-side key value to load the cross reference on.
     */
    mutating func load(from provider: ADDataProvider, forKeyValue key:Any) throws
    
}
