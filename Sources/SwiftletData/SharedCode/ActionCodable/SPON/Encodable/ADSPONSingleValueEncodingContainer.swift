//
//  ADSPONSingleValueEncodingContainer.swift
//  ActionControls
//
//  Created by Kevin Mullins on 10/13/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/// A SingleValueEncodingContainer used to store individual values while encoding an object. The data will be stored directly in the `ADEncodingStorage` during the encoding process.
struct ADSPONSingleValueEncodingContainer: SingleValueEncodingContainer {
    
    /// Holds an instance of the encoder.
    var encoder: ADSPONEncoder
    
    /// Holds the path to the object being encoded.
    var codingPath: [CodingKey]
    
    /// Holds the `ADEncodingStorage` for the object being encoded.
    var storage: ADEncodingStorage
    
    /**
     Initializes a new instance of the `ADSQLSingleValueEncodingContainer` and sets its initial properties.
     - Parameters:
         - encoder: The `ADSPONEncoder` for this container.
         - codingPath: The path to the object or value being encoded.
         - storage: The `ADEncodingStorage` that the object or value is being encoded into.
     */
    init(referencing encoder: ADSPONEncoder, codingPath: [CodingKey], into storage: ADEncodingStorage) {
        self.encoder = encoder
        self.codingPath = codingPath
        self.storage = storage
    }
    
    /**
     Encodes a `nil` into the storage container.
     */
    mutating func encodeNil() throws {
        storage.push(container: NSNull())
    }
    
    /**
     Encodes a Bool value into the storage container.
     - Parameter value: The value to encode.
     */
    mutating func encode(_ value: Bool) throws {
        // Add to storage
        storage.push(container: encoder.box(value))
    }
    
    /**
     Encodes a Int value into the storage container.
     - Parameter value: The value to encode.
     */
    mutating func encode(_ value: Int) throws {
        // Add to storage
        storage.push(container: encoder.box(value))
    }
    
    /**
     Encodes a Int8 value into the storage container.
     - Parameter value: The value to encode.
     */
    mutating func encode(_ value: Int8) throws {
        // Add to storage
        storage.push(container: encoder.box(value))
    }
    
    /**
     Encodes a Int16 value into the storage container.
     - Parameter value: The value to encode.
     */
    mutating func encode(_ value: Int16) throws {
        // Add to storage
        storage.push(container: encoder.box(value))
    }
    
    /**
     Encodes a Int32 value into the storage container.
     - Parameter value: The value to encode.
     */
    mutating func encode(_ value: Int32) throws {
        // Add to storage
        storage.push(container: encoder.box(value))
    }
    
    /**
     Encodes a Int64 value into the storage container.
     - Parameter value: The value to encode.
     */
    mutating func encode(_ value: Int64) throws {
        // Add to storage
        storage.push(container: encoder.box(value))
    }
    
    /**
     Encodes a UInt value into the storage container.
     - Parameter value: The value to encode.
     */
    mutating func encode(_ value: UInt) throws {
        // Add to storage
        storage.push(container: encoder.box(value))
    }
    
    /**
     Encodes a UInt8 value into the storage container.
     - Parameter value: The value to encode.
     */
    mutating func encode(_ value: UInt8) throws {
        // Add to storage
        storage.push(container: encoder.box(value))
    }
    
    /**
     Encodes a UInt16 value into the storage container.
     - Parameter value: The value to encode.
     */
    mutating func encode(_ value: UInt16) throws {
        // Add to storage
        storage.push(container: encoder.box(value))
    }
    
    /**
     Encodes a UInt32 value into the storage container.
     - Parameter value: The value to encode.
     */
    mutating func encode(_ value: UInt32) throws {
        // Add to storage
        storage.push(container: encoder.box(value))
    }
    
    /**
     Encodes a UInt64 value into the storage container.
     - Parameter value: The value to encode.
     */
    mutating func encode(_ value: UInt64) throws {
        // Add to storage
        storage.push(container: encoder.box(value))
    }
    
    /**
     Encodes a Float value into the storage container.
     - Parameter value: The value to encode.
     */
    mutating func encode(_ value: Float) throws {
        // Add to storage
        storage.push(container: encoder.box(value))
    }
    
    /**
     Encodes a Double value into the storage container.
     - Parameter value: The value to encode.
     */
    mutating func encode(_ value: Double) throws {
        // Add to storage
        storage.push(container: encoder.box(value))
    }
    
    /**
     Encodes a String value into the storage container.
     - Parameter value: The value to encode.
     */
    mutating func encode(_ value: String) throws {
        // Add to storage
        storage.push(container: encoder.box(value))
    }
    
    /**
     Encodes an `Encodable` value into the storage container.
     - Parameter value: The value to encode.
     */
    mutating func encode<T>(_ value: T) throws where T : Encodable {
        // Add to storage
        let subValue = try encoder.box(value)
        storage.push(container: subValue)
    }
}
