//
//  ADSQLKey.swift
//  CoderPlayground
//
//  Created by Kevin Mullins on 9/22/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/**
 Defines a Coding Key for use when providing a custom Coder for Action Data types. This includes the standard key used for a "super encoder", a string value used for path type keys (KeyedEncodingContainers) and an integer value used for index type keys (UnkeyedEncodingContainers).
*/
struct ADKey : CodingKey {
    
    // MARK: - Public Properties
    /// Defines the value used for the Super Key when encoding or decoding data.
    static var superKey: ADKey {
        return ADKey(stringValue: "super")!
    }
    
    /// The `String` value of the key.
    var stringValue: String
    
    /// The `Int` value of the key. This is usually an index in an array.
    var intValue: Int?
    
    // MARK: - Initializers
    /**
     Initializes a new key with the given string value.
     
     - Parameter stringValue: The name of the new key.
     */
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    /**
     Initializes a new key with the given integer value.
     
     - Parameter intValue: The integer value of the key.
     */
    init?(intValue: Int) {
        self.stringValue = ""
        self.intValue = intValue
    }
    
    /**
     Initializes a new key with the given integer value.
     
     - Parameter index: The index of the key within an array.
     */
    init(index: Int) {
        self.stringValue = ""
        self.intValue = index
    }
    
}
