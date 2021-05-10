//
//  ADSQLSingleValueDecodingContainer.swift
//  CoderPlayground
//
//  Created by Kevin Mullins on 9/27/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/// A SingleValueDecodingContainer used to read individual values while decoding an object. The data will be stored directly in the `ADDecodingStorage` during the decoding process.
struct ADSQLSingleValueDecodingContainer: SingleValueDecodingContainer {
    
    // MARK: - Properties
    /// Holds the parent `ADSQLDecoder`.
    var decoder: ADSQLDecoder
    
    /// Holds the path to the object being decided.
    var codingPath: [CodingKey]

    /// Holds the `ADDecodingStorage` for the object being decoded.
    var storage: ADDecodingStorage
    
    // MARK: - Initializers
    /**
     Initializes a new instance of the `ADSQLSingleValueDecodingContainer` and sets its initial properties.
     - Parameter decoder: The parent `ADSQLDecoder`.
    */
    init(referencing decoder: ADSQLDecoder) {
        self.decoder = decoder
        self.codingPath = decoder.codingPath
        self.storage = decoder.storage
    }
    
    // MARK: - Functions
    /**
     Decodes a `nil` value from the container.
     - Returns: `true` if the value is `nil`, else `false`.
    */
    func decodeNil() -> Bool {
        return self.storage.topContainer is NSNull
    }
    
    /**
     Decodes a given data type from the container.
     - Parameter type: The data type to decode to.
     - Returns: A Bool value from the container.
    */
    func decode(_ type: Bool.Type) throws -> Bool {
        try expectNonNull(Bool.self)
        return try decoder.unbox(self.storage.topContainer, as: Bool.self)!
    }
    
    /**
     Decodes a given data type from the container.
     - Parameter type: The data type to decode to.
     - Returns: A Int value from the container.
     */
    func decode(_ type: Int.Type) throws -> Int {
        try expectNonNull(Int.self)
        return try decoder.unbox(self.storage.topContainer, as: Int.self)!
    }
    
    /**
     Decodes a given data type from the container.
     - Parameter type: The data type to decode to.
     - Returns: A Int8 value from the container.
     */
    func decode(_ type: Int8.Type) throws -> Int8 {
        try expectNonNull(Int8.self)
        return try decoder.unbox(self.storage.topContainer, as: Int8.self)!
    }
    
    /**
     Decodes a given data type from the container.
     - Parameter type: The data type to decode to.
     - Returns: A Int16 value from the container.
     */
    func decode(_ type: Int16.Type) throws -> Int16 {
        try expectNonNull(Int16.self)
        return try decoder.unbox(self.storage.topContainer, as: Int16.self)!
    }
    
    /**
     Decodes a given data type from the container.
     - Parameter type: The data type to decode to.
     - Returns: A Int32 value from the container.
     */
    func decode(_ type: Int32.Type) throws -> Int32 {
        try expectNonNull(Int32.self)
        return try decoder.unbox(self.storage.topContainer, as: Int32.self)!
    }
    
    /**
     Decodes a given data type from the container.
     - Parameter type: The data type to decode to.
     - Returns: A Int64 value from the container.
     */
    func decode(_ type: Int64.Type) throws -> Int64 {
        try expectNonNull(Int64.self)
        return try decoder.unbox(self.storage.topContainer, as: Int64.self)!
    }
    
    /**
     Decodes a given data type from the container.
     - Parameter type: The data type to decode to.
     - Returns: A UInt value from the container.
     */
    func decode(_ type: UInt.Type) throws -> UInt {
        try expectNonNull(UInt.self)
        return try decoder.unbox(self.storage.topContainer, as: UInt.self)!
    }
    
    /**
     Decodes a given data type from the container.
     - Parameter type: The data type to decode to.
     - Returns: A UInt8 value from the container.
     */
    func decode(_ type: UInt8.Type) throws -> UInt8 {
        try expectNonNull(UInt8.self)
        return try decoder.unbox(self.storage.topContainer, as: UInt8.self)!
    }
    
    /**
     Decodes a given data type from the container.
     - Parameter type: The data type to decode to.
     - Returns: A UInt16 value from the container.
     */
    func decode(_ type: UInt16.Type) throws -> UInt16 {
        try expectNonNull(UInt16.self)
        return try decoder.unbox(self.storage.topContainer, as: UInt16.self)!
    }
    
    /**
     Decodes a given data type from the container.
     - Parameter type: The data type to decode to.
     - Returns: A UInt32 value from the container.
     */
    func decode(_ type: UInt32.Type) throws -> UInt32 {
        try expectNonNull(UInt32.self)
        return try decoder.unbox(self.storage.topContainer, as: UInt32.self)!
    }
    
    /**
     Decodes a given data type from the container.
     - Parameter type: The data type to decode to.
     - Returns: A UInt64 value from the container.
     */
    func decode(_ type: UInt64.Type) throws -> UInt64 {
        try expectNonNull(UInt64.self)
        return try decoder.unbox(self.storage.topContainer, as: UInt64.self)!
    }
    
    /**
     Decodes a given data type from the container.
     - Parameter type: The data type to decode to.
     - Returns: A Float value from the container.
     */
    func decode(_ type: Float.Type) throws -> Float {
        try expectNonNull(Float.self)
        return try decoder.unbox(self.storage.topContainer, as: Float.self)!
    }
    
    /**
     Decodes a given data type from the container.
     - Parameter type: The data type to decode to.
     - Returns: A Double value from the container.
     */
    func decode(_ type: Double.Type) throws -> Double {
        try expectNonNull(Double.self)
        return try decoder.unbox(self.storage.topContainer, as: Double.self)!
    }
    
    /**
     Decodes a given data type from the container.
     - Parameter type: The data type to decode to.
     - Returns: A String value from the container.
     */
    func decode(_ type: String.Type) throws -> String {
        try expectNonNull(String.self)
        return try decoder.unbox(self.storage.topContainer, as: String.self)!
    }
    
    /**
     Decodes a given data type from the container.
     - Parameter type: The data type to decode to.
     - Returns: A `Decodable` object value from the container.
     */
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        try expectNonNull(T.self)
        return try decoder.unbox(self.storage.topContainer, as: T.self)!
    }
    
    // MARK: - Private Functions
    /**
     Tests the given data type to ensure the value does not contain `nil` when it is not supported.
     - Parameter type: The data type to test for.
    */
    private func expectNonNull<T>(_ type: T.Type) throws {
        guard !self.decodeNil() else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected \(type) but found null value instead."))
        }
    }
    
}
