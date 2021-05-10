//
//  ADSQLRecord.swift
//  CoderPlayground
//
//  Created by Kevin Mullins on 9/22/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/**
 Defines a `ADRecord` as a dictionary of **Key/Value** pairs where the **Key** is a `String` and the **Value** is `Any` type. A `ADRecord` can be returned from or sent to a `ADDataProvider` or any of the **Action Codable** controls.
 
 ## Example:
 ```swift
 let provider = ADSQLiteProvider.shared
 let record = try provider.query("SELECT * FROM Categories WHERE id = ?", withParameters: [1])
 print(record["name"])
 ```
*/
public typealias ADRecord = [String:Any]

/**
 Defines an array of `ADRecord` instances that can be sent to or returned from a `ADDataProvider` or any of the **Action Codable** controls.
 
 ## Example:
 ```swift
 let provider = ADSQLiteProvider.shared
 let records = try provider.getRows(Category.self)
 
 for record in records {
     print(record["name"])
 }
 */
public typealias ADRecordSet = [ADRecord]
