//
//  ADSQLKeyedDecodingContainer.swift
//  CoderPlayground
//
//  Created by Kevin Mullins on 9/27/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/// A KeyedDecodingContainer used to read key/value pairs while decoding an object. The data will be stored in a `ADInstanceDictionary` during the decoding process.
struct ADSQLKeyedDecodingContainer<K: CodingKey>: KeyedDecodingContainerProtocol {
    
    /// Holds an alias to the type of object being decoded.
    typealias Key = K
    
    // MARK: - Properties
    /// Holds an instance of the parent `ADSQLDecoder`
    var decoder: ADSQLDecoder
    
    /// Holds an instance of the `ADRecord` being decoded.
    var container: ADRecord = ADRecord()
    
    /// Holds the path for the object being decoded.
    var codingPath: [CodingKey]
    
    /// Returns all of the keys for the object being decoded.
    var allKeys: [Key] {
        return container.keys.compactMap { Key(stringValue: $0) }
    }
    
    // MARK: - Initializers
    /**
     Initializes a new instance of the `ADSQLKeyedDecodingContainer` and sets its initial properties.
     - Parameters:
         - decoder: The parent `ADSQLDecoder`.
         - container: The `ADRecord` being decoded.
    */
    init(referencing decoder: ADSQLDecoder, wrapping container: ADRecord) {
        self.decoder = decoder
        self.container = container
        self.codingPath = decoder.codingPath
    }
    
    // MARK: - Functions
    /**
     Checks to see if the object contains the requested key.
     - Parameter key: The key to search for.
     - Returns: `true` if the object has the requested key, else `false`.
    */
    func contains(_ key: Key) -> Bool {
        return container[key.stringValue] != nil
    }
    
    /**
     Decodes a `nil` value from the container.
     - Parameter key: The key for the value to decode.
     - Returns: `true` if the `nil` can be decoded, else `false`.
    */
    func decodeNil(forKey key: Key) throws -> Bool {
        guard let entry = container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }
        
        return entry is NSNull
    }
    
    /**
     Decodes the value for the given key for the given type.
     - Parameter type: The data type to decode the value to.
     - Parameter key: The key to decode the value for.
     - Returns: A Bool value for the given key.
    */
    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        guard let entry = container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }
        
        decoder.codingPath.append(key)
        defer {
            if decoder.codingPath.count > 0 {
                decoder.codingPath.removeLast()
            }
        }
        
        guard let value = try decoder.unbox(entry, as: Bool.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }
        
        return value
    }
    
    /**
     Decodes the value for the given key for the given type.
     - Parameter type: The data type to decode the value to.
     - Parameter key: The key to decode the value for.
     - Returns: A Int value for the given key.
     */
    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        guard let entry = container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }
        
        decoder.codingPath.append(key)
        defer {
            if decoder.codingPath.count > 0 {
                decoder.codingPath.removeLast()
            }
        }
        
        guard let value = try self.decoder.unbox(entry, as: Int.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }
        
        return value
    }
    
    /**
     Decodes the value for the given key for the given type.
     - Parameter type: The data type to decode the value to.
     - Parameter key: The key to decode the value for.
     - Returns: A Int8 value for the given key.
     */
    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        guard let entry = container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }
        
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }
        
        guard let value = try decoder.unbox(entry, as: Int8.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }
        
        return value
    }
    
    /**
     Decodes the value for the given key for the given type.
     - Parameter type: The data type to decode the value to.
     - Parameter key: The key to decode the value for.
     - Returns: A Int16 value for the given key.
     */
    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        guard let entry = container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }
        
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }
        
        guard let value = try decoder.unbox(entry, as: Int16.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }
        
        return value
    }
    
    /**
     Decodes the value for the given key for the given type.
     - Parameter type: The data type to decode the value to.
     - Parameter key: The key to decode the value for.
     - Returns: A Int32 value for the given key.
     */
    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        guard let entry = container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }
        
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }
        
        guard let value = try decoder.unbox(entry, as: Int32.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }
        
        return value
    }
    
    /**
     Decodes the value for the given key for the given type.
     - Parameter type: The data type to decode the value to.
     - Parameter key: The key to decode the value for.
     - Returns: A Int64 value for the given key.
     */
    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        guard let entry = container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }
        
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }
        
        guard let value = try decoder.unbox(entry, as: Int64.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }
        
        return value
    }
    
    /**
     Decodes the value for the given key for the given type.
     - Parameter type: The data type to decode the value to.
     - Parameter key: The key to decode the value for.
     - Returns: A UInt value for the given key.
     */
    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        guard let entry = container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }
        
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }
        
        guard let value = try decoder.unbox(entry, as: UInt.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }
        
        return value
    }
    
    /**
     Decodes the value for the given key for the given type.
     - Parameter type: The data type to decode the value to.
     - Parameter key: The key to decode the value for.
     - Returns: A UInt8 value for the given key.
     */
    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        guard let entry = container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }
        
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }
        
        guard let value = try decoder.unbox(entry, as: UInt8.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }
        
        return value
    }
    
    /**
     Decodes the value for the given key for the given type.
     - Parameter type: The data type to decode the value to.
     - Parameter key: The key to decode the value for.
     - Returns: A UInt16 value for the given key.
     */
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        guard let entry = container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }
        
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }
        
        guard let value = try decoder.unbox(entry, as: UInt16.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }
        
        return value
    }
    
    /**
     Decodes the value for the given key for the given type.
     - Parameter type: The data type to decode the value to.
     - Parameter key: The key to decode the value for.
     - Returns: A UInt32 value for the given key.
     */
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        guard let entry = container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }
        
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }
        
        guard let value = try decoder.unbox(entry, as: UInt32.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }
        
        return value
    }
    
    /**
     Decodes the value for the given key for the given type.
     - Parameter type: The data type to decode the value to.
     - Parameter key: The key to decode the value for.
     - Returns: A UInt64 value for the given key.
     */
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        guard let entry = container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }
        
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }
        
        guard let value = try decoder.unbox(entry, as: UInt64.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }
        
        return value
    }
    
    /**
     Decodes the value for the given key for the given type.
     - Parameter type: The data type to decode the value to.
     - Parameter key: The key to decode the value for.
     - Returns: A Float value for the given key.
     */
    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        guard let entry = container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }
        
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }
        
        guard let value = try decoder.unbox(entry, as: Float.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }
        
        return value
    }
    
    /**
     Decodes the value for the given key for the given type.
     - Parameter type: The data type to decode the value to.
     - Parameter key: The key to decode the value for.
     - Returns: A Double value for the given key.
     */
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        guard let entry = container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }
        
        decoder.codingPath.append(key)
        defer {
            if decoder.codingPath.count > 0 {
                decoder.codingPath.removeLast()
            }
        }
        
        guard let value = try decoder.unbox(entry, as: Double.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }
        
        return value
    }
    
    /**
     Decodes the value for the given key for the given type.
     - Parameter type: The data type to decode the value to.
     - Parameter key: The key to decode the value for.
     - Returns: A String value for the given key.
     */
    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        guard let entry = container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }
        
        decoder.codingPath.append(key)
        defer {
            if decoder.codingPath.count > 0 {
                decoder.codingPath.removeLast()
            }
        }
        
        guard let value = try decoder.unbox(entry, as: String.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }
        
        return value
    }
    
    /**
     Decodes a `Decodable` value for the given key for the given type.
     - Parameter type: The data type to decode the value to.
     - Parameter key: The key to decode the value for.
     - Returns: An object value for the given key.
     */
    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
        guard let entry = container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }
        
        decoder.codingPath.append(key)
        defer {
            if decoder.codingPath.count > 0 {
                decoder.codingPath.removeLast()
            }
        }
        
        guard let value = try decoder.unbox(entry, as: T.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }
        
        return value
    }
    
    /**
     Decodes the nested container for the given key for the given type.
     - Parameter type: The nested key type to decode the value to.
     - Parameter key: The key to decode the value for.
     - Returns: A `KeyedDecodingContainer` value for the given key.
     */
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }
        
        guard let value = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key,
                                            DecodingError.Context(codingPath: self.codingPath,
                                                                  debugDescription: "Cannot get \(KeyedDecodingContainer<NestedKey>.self) -- no value found for key \"\(key.stringValue)\""))
        }

        guard let dictionary = value as? ADRecord else {
            // Report error
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Expected \(type) but received \(value)")
            throw DecodingError.typeMismatch(type, context)
        }

        let container = ADSQLKeyedDecodingContainer<NestedKey>(referencing: self.decoder, wrapping: dictionary)
        return KeyedDecodingContainer(container)
    }
    
    /**
     Decodes the unkeyed, nested container for the given key for the given type.
     - Parameter key: The key to decode the value for.
     - Returns: A `UnKeyedDecodingContainer` value for the given key.
     */
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }
        
        guard let value = container[key.stringValue] else {
            throw DecodingError.keyNotFound(key,
                                            DecodingError.Context(codingPath: self.codingPath,
                                                                  debugDescription: "Cannot get UnkeyedDecodingContainer -- no value found for key \"\(key.stringValue)\""))
        }
        
        guard let array = value as? [Any] else {
            // Report error
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Expected \(ADInstanceArray.self) but received \(value)")
            throw DecodingError.typeMismatch(ADInstanceArray.self, context)
        }
        
        return ADSQLUnkeyedDecodingContainer(referencing: self.decoder, wrapping: array)
    }
    
    /**
     Returns the super decoder for this object.
     - Returns: The super `Decoder`.
    */
    func superDecoder() throws -> Decoder {
        return try handleSuperDecoder(forKey: ADKey.superKey)
    }
    
    /**
     Returns the super ddecoder for this object.
     - Parameter key: The key to return the super decoder for.
     - Returns: The super `Decoder`.
    */
    func superDecoder(forKey key: Key) throws -> Decoder {
        return try handleSuperDecoder(forKey: key)
    }
    
    // MARK: - Private Functions
    /**
     Manages the super decoded for the given key.
     - Parameter key: The key to manage decoding for.
     - Returns: The super `Decoder`.
    */
    private func handleSuperDecoder(forKey key: CodingKey) throws -> Decoder {
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }
        
        let value: Any = container[key.stringValue] ?? NSNull()
        return ADSQLDecoder(referencing: value, at: self.decoder.codingPath, dateDecodingStrategy: decoder.dateDecodingStrategy, dataDecodingStrategy: decoder.dataDecodingStrategy)
    }
    
}
