//
//  ADSQLDecoder.swift
//  CoderPlayground
//
//  Created by Kevin Mullins on 9/22/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation
import SwiftletUtilities

/**
 Decodes a `Codable` or `Decodable` class from a `ADRecord` read from a SQLite database using a `ADSQLiteProvider`. The result is an instance of the class with the properties set from the database record. This decoder will automatically handle `URLs` and `Enums` (if the Enum is value based and also marked `Codable` or `Decodable`).
 
 ## Example:
 ```swift
 import SwiftletUtilities
 import SwiftletData
 
 class Category: ADDataTable {
 
     enum CategoryType: String, Codable {
         case local
         case web
     }
 
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
 
 let encoder = ADSQLEncoder()
 let category = Category()
 let data = try encoder.encode(category)
 
 let decoder = ADSQLDecoder()
 let category2 = try decoder.decode(Category.self, from: data)
 ```
 
 - Remark: To retrieve `UIColors` in the record use the `String.uiColor` extension property and to retrieve `UIImages` use the `String.uiImage` extension property.
 */
public class ADSQLDecoder: Decoder {

    // MARK: - Enumerations
    /// The strategy to use for encoding `Date` values.
    public enum DateDecodingStrategy {
        /// The raw `Date` instance is encoded in the `ADRecord` directly from a SQL Data Provider. This is the default strategy.
        case rawDate
        
        /// Defer to `Date` for choosing an encoding.
        case deferredToDate
        
        /// Encode the `Date` as a UNIX timestamp (as a JSON number).
        case secondsSince1970
        
        /// Encode the `Date` as UNIX millisecond timestamp (as a JSON number).
        case millisecondsSince1970
        
        /// Encode the `Date` as an ISO-8601-formatted string (in RFC 3339 format).
        @available(OSX 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
        case iso8601
        
        /// Encode the `Date` as a string formatted by the given formatter.
        case formatted(DateFormatter)
    }
    
    /// The strategy to use for encoding `Data` values.
    public enum DataDecodingStrategy {
        /// The raw `Data` instance is encoded in the `ADRecord` directly from a SQL Data Provider. This is the default strategy.
        case rawData
        
        /// Defer to `Data` for choosing an encoding.
        case deferredToData
        
        /// Encoded the `Data` as a Base64-encoded string.
        case base64
    }
    
    // MARK: - Class Functions
    /**
     Checks to see if a sqlObject is stored in the given data stream and returns it if it is.
     
     - Parameter data: The data to check for a `ADRecord` or `ADRecord` array.
     - Returns: The `ADRecord` or `ADRecord` array if found, else `nil`.
     */
    public static func sqlObject(in data: Any) -> Any? {
        // Ensure data is of a valid type
        if (data is ADRecord) || (data is [ADRecord]) {
            // Valid data, return
            return data
        } else {
            // Not valid
            return nil
        }
    }
    
    /// Shared formatter used to encode a `Date` as an ISO-8601-formatted string (in RFC 3339 format).
    @available(OSX 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
    public static var iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = .withInternetDateTime
        return formatter
    }()
    
    // MARK: - Properties
    /// The path to the current value that is being decoded.
    public var codingPath: [CodingKey] = []

    /// User spsecific information that can be used when decoding an item.
    public var userInfo: [CodingUserInfoKey : Any] = [:]
    
    /// Temporary storage for the items being decoded.
    internal var storage: ADDecodingStorage = ADDecodingStorage()
    
    /// The strategy used to decode `Date` properties. The default is `rawDate` which allow the `ADSQLiteProvider` to handle the date directly.
    public var dateDecodingStrategy: DateDecodingStrategy = .rawDate
    
    /// The strategy used to encode `Data` or `NSData` properties. The default is `rawData` which allow the `ADSQLiteProvider` to handle the data directly.
    public var dataDecodingStrategy: DataDecodingStrategy = .rawData

    // MARK: - Initializers
    /**
     Creates a new instance of the decoder.
     
     - Parameters:
         - dateDecodingStrategy: The strategy used to decode `Date` properties. The default is `rawDate` which allow the `ADSQLiteProvider` to handle the date directly.
         - dataDecodingStrategy: The strategy used to decode `Data` or `NSData` properties. The default is `rawData` which allow the `ADSQLiteProvider` to handle the data directly.
     */
    public init(dateDecodingStrategy: DateDecodingStrategy = .rawDate, dataDecodingStrategy: DataDecodingStrategy = .rawData) {
        self.dateDecodingStrategy = dateDecodingStrategy
        self.dataDecodingStrategy = dataDecodingStrategy
    }
    
    /**
     Creates a new instance of the decoder.
     
     - Parameters:
         - container: Storage for the object being decoded.
         - codingPath: The path to the object being decoded.
         - dateDecodingStrategy: The strategy used to decode `Date` properties. The default is `rawDate` which allow the `ADSQLiteProvider` to handle the date directly.
         - dataDecodingStrategy: The strategy used to decode `Data` or `NSData` properties. The default is `rawData` which allow the `ADSQLiteProvider` to handle the data directly.
     */
    internal init(referencing container: Any, at codingPath: [CodingKey] = [], dateDecodingStrategy: DateDecodingStrategy = .rawDate, dataDecodingStrategy: DataDecodingStrategy = .rawData) {
        self.storage.push(container: container)
        self.codingPath = codingPath
        self.dateDecodingStrategy = dateDecodingStrategy
        self.dataDecodingStrategy = dataDecodingStrategy
    }

    // MARK: - Public Functions
    /**
     Decodes a `Codable` or `Decodable` class from a `ADRecord` read from a SQLite database using a `ADSQLiteProvider`. The result is an instance of the class with the properties set from the database record. This decoder will automatically handle `URLs` and `Enums` (if the Enum is value based and also marked `Codable` or `Decodable`). For example:
     
     ```swift
     enum SwitchState: String, Codable {
     case on
     case off
     }
     ```
     
     ## Example Usage
     
     ```swift
     let record = ADSQLiteProvider.shared.query("SELECT * FROM TASKS WHERE ID=1")
     let decoder = ADSQLDecoder()
     let task = decoder.decode(Task, from: record)
     ```
     
     - Parameters:
         - type: The type of class to decode the data to.
         - data: The data to decode.
     - Remark: To retrieve `UIColors` in the record use the `String.uiColor` extension property and to retrieve `UIImages` use the `String.uiImage` extension property.
     - Returns: The data decoded to one (or more) instances of the given class.
     */
    public func decode<T : Decodable>(_ type: T.Type, from data: Any) throws -> T {
        
        // Ensure data is of a valid type
        guard let topLevel = ADSQLDecoder.sqlObject(in: data) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "The given data was not valid SQL."))
        }
        
        // Unbox and return
        guard let value = try unbox(topLevel, as: T.self) else {
            throw DecodingError.valueNotFound(T.self, DecodingError.Context(codingPath: [], debugDescription: "The given data did not contain a top-level value."))
        }
        
        return value
    }

    /**
     Returns the keyed decoding container for the given key type.
     - Parameter type: The key of key to return to container for.
     - Returns: A `KeyedDecodingContainer` for the given key.
    */
    public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        guard !(self.storage.topContainer is NSNull) else {
            throw DecodingError.valueNotFound(KeyedDecodingContainer<Key>.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get keyed decoding container -- found null value instead."))
        }
        
        // Check for sub container and decode
        var topContainer: ADRecord
        if let d = self.storage.topContainer as? ADInstanceDictionary {
            topContainer = d.storage
        } else if self.storage.topContainer is ADRecord {
            topContainer = self.storage.topContainer as! ADRecord
        } else {
            // Report error
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Expected \(ADRecord.self) but received \(storage.topContainer)")
            throw DecodingError.typeMismatch(type, context)
        }
        
        let container = ADSQLKeyedDecodingContainer<Key>(referencing: self, wrapping: topContainer)
        return KeyedDecodingContainer(container)
    }

    /**
     Returns an unkeyed decoding container.
     - Returns: A `UnkeyedDecodingContainer`.
    */
    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        guard !(self.storage.topContainer is NSNull) else {
            throw DecodingError.valueNotFound(UnkeyedDecodingContainer.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get unkeyed decoding container -- found null value instead."))
        }
        
        // Check for sub container and decode
        var topContainer: [Any]
        if let array = self.storage.topContainer as? ADInstanceArray {
            topContainer = array.storage
        } else if self.storage.topContainer is [Any] {
            topContainer = self.storage.topContainer as! [Any]
        } else {
            // Report error
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Expected \([Any].self) but received \(storage.topContainer)")
            throw DecodingError.typeMismatch([Any].self, context)
        }
        
        return ADSQLUnkeyedDecodingContainer(referencing: self, wrapping: topContainer)
    }

    /**
     Returns a single value decoding container.
     - Returns: A `SingleValueDecodingContainer`.
    */
    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        return ADSQLSingleValueDecodingContainer(referencing: self)
    }

    // MARK: - Unboxing Routines
    /**
     Unboxes the given value to the requested type.
     - Parameter value: The value to unbox.
     - Parameter type: The data type to unbox the value to.
     - Returns: A Bool representing the unboxed value.
    */
    internal func unbox(_ value: Any, as type: Bool.Type) throws -> Bool? {
        guard !(value is NSNull) else { return nil }
        
        // Try all the possible variations of a bool value
        if let bool = value as? Bool {
            return bool
        } else if let int = value as? Int {
            return (int == 1)
        } else if let string = value as? String {
            return (string == "true" || string == "yes" || string == "on")
        }
        
        // Report error
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Expected \(type) but received \(value)")
        throw DecodingError.typeMismatch(type, context)
    }
    
    /**
     Unboxes the given value to the requested type.
     - Parameter value: The value to unbox.
     - Parameter type: The data type to unbox the value to.
     - Returns: A Int representing the unboxed value.
     */
    internal func unbox(_ value: Any, as type: Int.Type) throws -> Int? {
        guard !(value is NSNull) else { return nil }
        
        if let int = value as? Int {
            return int
        }
        
        // Report error
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Expected \(type) but received \(value)")
        throw DecodingError.typeMismatch(type, context)
    }
    
    /**
     Unboxes the given value to the requested type.
     - Parameter value: The value to unbox.
     - Parameter type: The data type to unbox the value to.
     - Returns: A Int8 representing the unboxed value.
     */
    internal func unbox(_ value: Any, as type: Int8.Type) throws -> Int8? {
        guard !(value is NSNull) else { return nil }
        
        if let int = value as? Int8 {
            return int
        }
        
        // Report error
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Expected \(type) but received \(value)")
        throw DecodingError.typeMismatch(type, context)
    }
    
    /**
     Unboxes the given value to the requested type.
     - Parameter value: The value to unbox.
     - Parameter type: The data type to unbox the value to.
     - Returns: A Int16 representing the unboxed value.
     */
    internal func unbox(_ value: Any, as type: Int16.Type) throws -> Int16? {
        guard !(value is NSNull) else { return nil }
        
        if let int = value as? Int16 {
            return int
        }
        
        // Report error
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Expected \(type) but received \(value)")
        throw DecodingError.typeMismatch(type, context)
    }
    
    /**
     Unboxes the given value to the requested type.
     - Parameter value: The value to unbox.
     - Parameter type: The data type to unbox the value to.
     - Returns: A Int32 representing the unboxed value.
     */
    internal func unbox(_ value: Any, as type: Int32.Type) throws -> Int32? {
        guard !(value is NSNull) else { return nil }
        
        if let int = value as? Int32 {
            return int
        }
        
        // Report error
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Expected \(type) but received \(value)")
        throw DecodingError.typeMismatch(type, context)
    }
    
    /**
     Unboxes the given value to the requested type.
     - Parameter value: The value to unbox.
     - Parameter type: The data type to unbox the value to.
     - Returns: A Int64 representing the unboxed value.
     */
    internal func unbox(_ value: Any, as type: Int64.Type) throws -> Int64? {
        guard !(value is NSNull) else { return nil }
        
        if let int = value as? Int64 {
            return int
        }
        
        // Report error
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Expected \(type) but received \(value)")
        throw DecodingError.typeMismatch(type, context)
    }
    
    /**
     Unboxes the given value to the requested type.
     - Parameter value: The value to unbox.
     - Parameter type: The data type to unbox the value to.
     - Returns: A UInt representing the unboxed value.
     */
    internal func unbox(_ value: Any, as type: UInt.Type) throws -> UInt? {
        guard !(value is NSNull) else { return nil }
        
        if let int = value as? UInt {
            return int
        }
        
        // Report error
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Expected \(type) but received \(value)")
        throw DecodingError.typeMismatch(type, context)
    }
    
    /**
     Unboxes the given value to the requested type.
     - Parameter value: The value to unbox.
     - Parameter type: The data type to unbox the value to.
     - Returns: A UInt8 representing the unboxed value.
     */
    internal func unbox(_ value: Any, as type: UInt8.Type) throws -> UInt8? {
        guard !(value is NSNull) else { return nil }
        
        if let int = value as? UInt8 {
            return int
        }
        
        // Report error
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Expected \(type) but received \(value)")
        throw DecodingError.typeMismatch(type, context)
    }
    
    /**
     Unboxes the given value to the requested type.
     - Parameter value: The value to unbox.
     - Parameter type: The data type to unbox the value to.
     - Returns: A UInt16 representing the unboxed value.
     */
    internal func unbox(_ value: Any, as type: UInt16.Type) throws -> UInt16? {
        guard !(value is NSNull) else { return nil }
        
        if let int = value as? UInt16 {
            return int
        }
        
        // Report error
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Expected \(type) but received \(value)")
        throw DecodingError.typeMismatch(type, context)
    }
    
    /**
     Unboxes the given value to the requested type.
     - Parameter value: The value to unbox.
     - Parameter type: The data type to unbox the value to.
     - Returns: A UInt32 representing the unboxed value.
     */
    internal func unbox(_ value: Any, as type: UInt32.Type) throws -> UInt32? {
        guard !(value is NSNull) else { return nil }
        
        if let int = value as? UInt32 {
            return int
        }
        
        // Report error
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Expected \(type) but received \(value)")
        throw DecodingError.typeMismatch(type, context)
    }
    
    /**
     Unboxes the given value to the requested type.
     - Parameter value: The value to unbox.
     - Parameter type: The data type to unbox the value to.
     - Returns: A UInt64 representing the unboxed value.
     */
    internal func unbox(_ value: Any, as type: UInt64.Type) throws -> UInt64? {
        guard !(value is NSNull) else { return nil }
        
        if let int = value as? UInt64 {
            return int
        }
        
        // Report error
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Expected \(type) but received \(value)")
        throw DecodingError.typeMismatch(type, context)
    }
    
    /**
     Unboxes the given value to the requested type.
     - Parameter value: The value to unbox.
     - Parameter type: The data type to unbox the value to.
     - Returns: A Float representing the unboxed value.
     */
    internal func unbox(_ value: Any, as type: Float.Type) throws -> Float? {
        guard !(value is NSNull) else { return nil }
        
        if let float = value as? Float {
            return float
        }
        
        // Report error
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Expected \(type) but received \(value)")
        throw DecodingError.typeMismatch(type, context)
    }
    
    /**
     Unboxes the given value to the requested type.
     - Parameter value: The value to unbox.
     - Parameter type: The data type to unbox the value to.
     - Returns: A Double representing the unboxed value.
     */
    internal func unbox(_ value: Any, as type: Double.Type) throws -> Double? {
        guard !(value is NSNull) else { return nil }
        
        if let double = value as? Double {
            return double
        }
        
        // Report error
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Expected \(type) but received \(value)")
        throw DecodingError.typeMismatch(type, context)
    }
    
    /**
     Unboxes the given value to the requested type.
     - Parameter value: The value to unbox.
     - Parameter type: The data type to unbox the value to.
     - Returns: A String representing the unboxed value.
     */
    internal func unbox(_ value: Any, as type: String.Type) throws -> String? {
        guard !(value is NSNull) else { return nil }
        
        guard let string = value as? String else {
            // Report error
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Expected \(type) but received \(value)")
            throw DecodingError.typeMismatch(type, context)
        }
        
        return string
    }
    
    /**
     Unboxes the given value to the requested type.
     - Parameter value: The value to unbox.
     - Parameter type: The data type to unbox the value to.
     - Returns: A Date representing the unboxed value.
     */
    internal func unbox(_ value: Any, as type: Date.Type) throws -> Date? {
        guard !(value is NSNull) else { return nil }
        
        // Is this a string encoded date?
        if let ds = value as? String {
            if case .formatted(_) = dateDecodingStrategy {
                // Ignore
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
                guard let dt = formatter.date(from: ds)  else {
                    throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Date string does not match `yyyy-MM-dd HH:mm:ss Z` format expected by formatter."))
                }
                return dt
            }
        }
        
        switch dateDecodingStrategy {
        case .rawDate:
            return value as? Date
        case .deferredToDate:
            self.storage.push(container: value)
            let date = try Date(from: self)
            self.storage.popContainer()
            return date
        case .secondsSince1970:
            let double = try self.unbox(value, as: Double.self)!
            return Date(timeIntervalSince1970: double)
        case .millisecondsSince1970:
            let double = try self.unbox(value, as: Double.self)!
            return Date(timeIntervalSince1970: double / 1000.0)
        case .iso8601:
            if #available(OSX 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *) {
                let string = try self.unbox(value, as: String.self)!
                guard let date = ADSQLDecoder.iso8601Formatter.date(from: string) else {
                    throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected date string to be ISO8601-formatted."))
                }
                
                return date
            } else {
                fatalError("ISO8601DateFormatter is unavailable on this platform.")
            }
        case .formatted(let formatter):
            let string = try self.unbox(value, as: String.self)!
            guard let date = formatter.date(from: string) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Date string does not match format expected by formatter."))
            }
            
            return date
        }
    }
    
    /**
     Unboxes the given value to the requested type.
     - Parameter value: The value to unbox.
     - Parameter type: The data type to unbox the value to.
     - Returns: A Data representing the unboxed value.
     */
    internal func unbox(_ value: Any, as type: Data.Type) throws -> Data? {
        guard !(value is NSNull) else { return nil }
        
        switch dataDecodingStrategy {
        case .rawData:
            return value as? Data
        case .deferredToData:
            self.storage.push(container: value)
            let data = try Data(from: self)
            self.storage.popContainer()
            return data
        case .base64:
            guard let string = value as? String else {
                // Report error
                let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Expected \(type) but received \(value)")
                throw DecodingError.typeMismatch(type, context)
            }
            
            guard let data = Data(base64Encoded: string) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Encountered Data is not valid Base64."))
            }
            
            return data
        }
    }
    
    /**
     Unboxes the given value to the requested type.
     - Parameter value: The value to unbox.
     - Parameter type: The data type to unbox the value to.
     - Returns: A Decimal representing the unboxed value.
     */
    internal func unbox(_ value: Any, as type: Decimal.Type) throws -> Decimal? {
        guard !(value is NSNull) else { return nil }
        
        // Attempt to bridge from NSDecimalNumber.
        if let decimal = value as? Decimal {
            return decimal
        } else {
            let doubleValue = try self.unbox(value, as: Double.self)!
            return Decimal(doubleValue)
        }
    }
    
    /**
     Unboxes the given `Decodable` value to the requested type.
     - Parameter value: The value to unbox.
     - Parameter type: The data type to unbox the value to.
     - Returns: An object representing the unboxed value.
     */
    internal func unbox<T : Decodable>(_ value: Any, as type: T.Type) throws -> T? {
        let decoded: T
        if T.self == Date.self || T.self == NSDate.self {
            guard let date = try self.unbox(value, as: Date.self) else { return nil }
            decoded = date as! T
        } else if T.self == Data.self || T.self == NSData.self {
            guard let data = try self.unbox(value, as: Data.self) else { return nil }
            decoded = data as! T
        } else if T.self == URL.self || T.self == NSURL.self {
            guard let urlString = try self.unbox(value, as: String.self) else {
                return nil
            }
            
            guard let url = URL(string: urlString) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath,
                                                                        debugDescription: "Invalid URL string."))
            }
            
            decoded = (url as! T)
        } else if T.self == Decimal.self || T.self == NSDecimalNumber.self {
            guard let decimal = try self.unbox(value, as: Decimal.self) else { return nil }
            decoded = decimal as! T
        } else if let dictionary = value as? ADInstanceDictionary {
            self.storage.push(container: dictionary.storage)
            decoded = try T(from: self)
            self.storage.popContainer()
        } else if let array = value as? ADInstanceArray {
            self.storage.push(container: array.storage)
            decoded = try T(from: self)
            self.storage.popContainer()
        } else if value is ADDataCrossReference {
            decoded = value as! T
        } else {
            if let string = value as? String {
                if string.prefix(4) == "@obj" {
                    self.storage.push(container: ADInstanceDictionary.decode(string).storage)
                } else if string.prefix(7) == "@array[" {
                    self.storage.push(container: ADInstanceArray.decode(string).storage)
                } else {
                    self.storage.push(container: string)
                }
            } else {
                self.storage.push(container: value)
            }
            
            decoded = try T(from: self)
            self.storage.popContainer()
        }
        
        return decoded
    }
}

