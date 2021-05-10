//
//  ADSPONKeyedEncodingContainer.swift
//  ActionControls
//
//  Created by Kevin Mullins on 10/13/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/// A KeyedEncodingContainer used to store key/value pairs while encoding an object. The data will be stored in a `ADInstanceDictionary` during the encoding process.
struct ADSPONKeyedEncodingContainer<K: CodingKey>: KeyedEncodingContainerProtocol {
    /// Holds an alias to the type of object being encoded.
    typealias Key = K
    
    /// Holds an instance of the `ADSQLEncoder`.
    var encoder: ADSPONEncoder
    
    /// Holds the path to the object being encoded.
    var codingPath: [CodingKey]
    
    /// Holds the `ADInstanceDictionary` that the object is being incoded into.
    var container: ADInstanceDictionary
    
    /**
     Creates a new instance of the `ADSQLKeyedEncodingContainer` and sets its initial properties.
     - Parameters:
         - encoder: The `ADSPONEncoder` that is creating the container.
         - codingPath: The path to the object being encoded.
         - container: The `ADInstanceDictionary` that the object is being encoded into.
     */
    init(referencing encoder: ADSPONEncoder, codingPath: [CodingKey], wrapping container: ADInstanceDictionary) {
        self.encoder = encoder
        self.codingPath = codingPath
        self.container = container
    }
    
    /**
     Encodes a `nil` into the container for the given key.
     - Parameter key: The key that the `nil` will be encoded for.
     */
    mutating func encodeNil(forKey key: K) throws {
        container.storage[key.stringValue] = NSNull()
    }
    
    /**
     Encodes a Bool value into the container.
     - Parameter value: The value to encode.
     - Parameter key: The key to store the value under.
     */
    mutating func encode(_ value: Bool, forKey key: K) throws {
        // Encode data into ADSPONRecord
        container.storage[key.stringValue] = encoder.box(value)
    }
    
    /**
     Encodes a Int value into the container.
     - Parameter value: The value to encode.
     - Parameter key: The key to store the value under.
     */
    mutating func encode(_ value: Int, forKey key: K) throws {
        // Encode data into ADSPONRecord
        container.storage[key.stringValue] = encoder.box(value)
    }
    
    /**
     Encodes a Int8 value into the container.
     - Parameter value: The value to encode.
     - Parameter key: The key to store the value under.
     */
    mutating func encode(_ value: Int8, forKey key: K) throws {
        // Encode data into ADSPONRecord
        container.storage[key.stringValue] = encoder.box(value)
    }
    
    /**
     Encodes a Int16 value into the container.
     - Parameter value: The value to encode.
     - Parameter key: The key to store the value under.
     */
    mutating func encode(_ value: Int16, forKey key: K) throws {
        // Encode data into ADSPONRecord
        container.storage[key.stringValue] = encoder.box(value)
    }
    
    /**
     Encodes a Int32 value into the container.
     - Parameter value: The value to encode.
     - Parameter key: The key to store the value under.
     */
    mutating func encode(_ value: Int32, forKey key: K) throws {
        // Encode data into ADSPONRecord
        container.storage[key.stringValue] = encoder.box(value)
    }
    
    /**
     Encodes a Int64 value into the container.
     - Parameter value: The value to encode.
     - Parameter key: The key to store the value under.
     */
    mutating func encode(_ value: Int64, forKey key: K) throws {
        // Encode data into ADSPONRecord
        container.storage[key.stringValue] = encoder.box(value)
    }
    
    /**
     Encodes a Bool UInt into the container.
     - Parameter value: The value to encode.
     - Parameter key: The key to store the value under.
     */
    mutating func encode(_ value: UInt, forKey key: K) throws {
        // Encode data into ADSPONRecord
        container.storage[key.stringValue] = encoder.box(value)
    }
    
    /**
     Encodes a UInt8 value into the container.
     - Parameter value: The value to encode.
     - Parameter key: The key to store the value under.
     */
    mutating func encode(_ value: UInt8, forKey key: K) throws {
        // Encode data into ADSPONRecord
        container.storage[key.stringValue] = encoder.box(value)
    }
    
    /**
     Encodes a UInt16 value into the container.
     - Parameter value: The value to encode.
     - Parameter key: The key to store the value under.
     */
    mutating func encode(_ value: UInt16, forKey key: K) throws {
        // Encode data into ADSPONRecord
        container.storage[key.stringValue] = encoder.box(value)
    }
    
    /**
     Encodes a UInt32 value into the container.
     - Parameter value: The value to encode.
     - Parameter key: The key to store the value under.
     */
    mutating func encode(_ value: UInt32, forKey key: K) throws {
        // Encode data into ADSPONRecord
        container.storage[key.stringValue] = encoder.box(value)
    }
    
    /**
     Encodes a UInt64 value into the container.
     - Parameter value: The value to encode.
     - Parameter key: The key to store the value under.
     */
    mutating func encode(_ value: UInt64, forKey key: K) throws {
        // Encode data into ADSPONRecord
        container.storage[key.stringValue] = encoder.box(value)
    }
    
    /**
     Encodes a Float value into the container.
     - Parameter value: The value to encode.
     - Parameter key: The key to store the value under.
     */
    mutating func encode(_ value: Float, forKey key: K) throws {
        // Encode data into ADSPONRecord
        container.storage[key.stringValue] = encoder.box(value)
    }
    
    /**
     Encodes a Double value into the container.
     - Parameter value: The value to encode.
     - Parameter key: The key to store the value under.
     */
    mutating func encode(_ value: Double, forKey key: K) throws {
        // Encode data into ADSPONRecord
        container.storage[key.stringValue] = encoder.box(value)
    }
    
    /**
     Encodes a String value into the container.
     - Parameter value: The value to encode.
     - Parameter key: The key to store the value under.
     */
    mutating func encode(_ value: String, forKey key: K) throws {
        // Encode data into ADSPONRecord
        container.storage[key.stringValue] = encoder.box(value)
    }
    
    /**
     Encodes an `Encodable` object value into the container.
     - Parameter value: The value to encode.
     - Parameter key: The key to store the value under.
     */
    mutating func encode<T>(_ value: T, forKey key: K) throws where T : Encodable {
        
        // Assemble key path
        encoder.codingPath.append(key)
        defer { encoder.codingPath.removeLast() }
        
        // Encode data into ADSPONRecord
        container.storage[key.stringValue] = try encoder.box(value)
    }
    
    /**
     Encodes a nested, keyed object into the container such as a `Dictionary`.
     - Parameter keyType: The type of the nested key.
     - Parameter key: The key to store the value under.
     - Returns: A `KeyedEncodingContainer` containing the nested object.
     */
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        
        // Build storage and accumulate under key
        let record = ADInstanceDictionary()
        container.storage[key.stringValue] = record
        
        // Assemble key path
        codingPath.append(key)
        defer { codingPath.removeLast() }
        
        // Assemble sub container and return
        let subContainer = ADSPONKeyedEncodingContainer<NestedKey>(referencing: encoder, codingPath: codingPath, wrapping: record)
        return KeyedEncodingContainer(subContainer)
    }
    
    /**
     Encodes a nested, unkeyed object into the container such as an `Array`.
     - Parameter key: The key to store the object under.
     - Returns: An `UnkeyedEncodingContainer` containing the encoded object.
     */
    mutating func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
        
        // Build storage and accumulate under key
        let array = ADInstanceArray()
        container.storage[key.stringValue] = array
        
        // Assemble key path
        codingPath.append(key)
        defer { codingPath.removeLast() }
        
        return ADSPONUnkeyedEncodingContainer(referencing: encoder, codingPath: codingPath, wrapping: array)
    }
    
    /**
     An unkeyed super encoder for the object being encoded.
     - Returns: An `Encoder` representing the super encode for the current object being encoded.
     */
    mutating func superEncoder() -> Encoder {
        return ADSPONReferencingEncoder(referencing: encoder, at: ADKey.superKey, wrapping: container)
    }
    
    /**
     A keyed super encoder for the object being encoded.
     - Parameter key: The key for the super encoder.
     - Returns: An `Encoder` representing the super encode for the current object being encoded.
     */
    mutating func superEncoder(forKey key: K) -> Encoder {
        return ADSPONReferencingEncoder(referencing: encoder, at: key, wrapping: container)
    }
    
}
