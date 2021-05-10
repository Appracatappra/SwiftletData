//
//  ADInstanceArray.swift
//  CoderPlayground
//
//  Created by Kevin Mullins on 9/26/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/**
 Defines a passable array of values used as temporary storage when encoding or decoding an Action Data class. `ADInstanceArray` also introduces support for the new **Swift Portable Object Notation** (SPON) data format that allows complex data models to be encoded in a portable text string that encodes not only property keys and data, but also includes type information about the encoded data. For example:
 
 ## Example:
 ```swift
 let data = "@array[1!, 2!, 3!, 4!]"
 let array = ADInstanceArray.decode(data)
 ```
 
 The portable, human-readable string format encodes values with a single character _type designator_ as follows:
 
 * `%` - Bool
 * `!` - Int
 * `$` - String
 * `^` - Float
 * `&` - Double
 * `*` - Embedded `NSData` or `Data` value
 
 Additionally, embedded arrays will be in the `@array[...]` format and embedded dictionaries in the `@obj:type<...>` format.
 */
public class ADInstanceArray {
    
    // MARK: - Enumerations
    /// Defines the current parse state when decoding a string representation of the array.
    private enum parserState {
        /// Seeking the start of the array.
        case seekArray
        
        /// Seeking the start of a value.
        case seekValue
        
        /// Assembling a value.
        case inValue
        
        /// Inside a nested array.
        case inArray
        
        /// Inside a nested array value.
        case inArrayValue
        
        /// Inside a nested `ADInstanceDictionary`.
        case inDictionary
        
        /// Inside a nested `ADInstanceDictionary` value.
        case inDictionaryValue
    }
    
    // MARK: - Class Functions
    /**
     Converts a given value into a format that can be safely stored in an `ADInstanceArray` portable, human-readable string format.
     
     - Parameter value: The string value to be escaped.
     - Returns: The string with any non-safe characters encoded in a safe format.
     */
    public static func escapeValue(_ value: String) -> String {
        let result = value.replacingOccurrences(of: "`", with: "&01;")
        return result
    }
    
    /**
     Converts a value stored in portable, human-readable string format and converts it back to its original format.
     
     - Parameter value: The string including any escaped values.
     - Returns: The string with any escaped values converted back to their original format
     */
    public static func unescapeValue(_ value: String) -> String {
        let result = value.replacingOccurrences(of: "&01;", with: "`")
        return result
    }
    
    /**
     Takes a `ADInstanceArray` object stored in a portable, human-readable string format and converts it to an array of the original values.
     
     ## Example:
     
     ```swift
     let data = "@array[1!, 2!, 3!, 4!]"
     let array = ADInstanceArray.decode(data)
     ```
     
     ## Data Types
     The portable, human-readable string format encodes values with a single character _type designator_ as follows:
     
     * `%` - Bool
     * `!` - Int
     * ` - String
     * `^` - Float
     * `&` - Double
     
     Additionally, embedded arrays (`ADInstanceArray`) will be in the `@array[...]` format and embedded dictionaries (`ADInstanceDictionary`) in the `@obj:type<...>` format.
     
     - Parameter text: The string in the portable, human-readable string format.
     - Returns: An instance array of the original Swift object values.
     */
    public static func decode(_ text: String) -> ADInstanceArray {
        let array = ADInstanceArray()
        var state: parserState = .seekArray
        var value = ""
        var nest = 0
        
        for c in text {
            let char = String(c)
            
            switch(char) {
            case "[":
                switch(state) {
                case .seekArray:
                    state = .seekValue
                    value = ""
                case .seekValue, .inValue:
                    state = .inArray
                    nest = 1
                    value += char
                case .inArray:
                    nest += 1
                    value += char
                default:
                    value += char
                }
            case "<":
                switch(state) {
                case .seekValue, .inValue:
                    state = .inDictionary
                    nest = 1
                    value += char
                case .inDictionary:
                    nest += 1
                    value += char
                default:
                    value += char
                }
            case ">":
                switch(state) {
                case .inDictionaryValue:
                    value += char
                case .inDictionary:
                    value += char
                    nest -= 1
                    if nest <= 0 {
                        // Convert dictionary and story in array
                        array.storage.append(ADInstanceDictionary.decode(value))
                        state = .seekValue
                        value = ""
                    }
                default:
                    value += char
                }
            case " ":
                switch(state){
                case .seekValue:
                    // Ignore spaces while seeking values
                    break
                default:
                    value += char
                }
            case "`":
                switch(state){
                case .seekValue:
                    state = .inValue
                case .inDictionary:
                    state = .inDictionaryValue
                    value += char
                case .inDictionaryValue:
                    state = .inDictionary
                    value += char
                case .inArray:
                    state = .inArrayValue
                    value += char
                case .inArrayValue:
                    state = .inArray
                    value += char
                default:
                    value += char
                }
            case ",":
                switch(state) {
                case .inValue:
                    // Found value/type pair - store
                    let type = String(value.last!)
                    value = String(value.prefix(value.count - 1))
                    
                    switch(type) {
                    case "%":
                        array.storage.append((value == "true") ? true : false)
                    case "!":
                        array.storage.append(Int(value)!)
                    case "^":
                        array.storage.append(Float(value)!)
                    case "&":
                        array.storage.append(Double(value)!)
                    case "*":
                        array.storage.append(Data(base64Encoded: value)!)
                    default:
                        array.storage.append(ADInstanceDictionary.unescapeValue(value))
                    }
                    
                    state = .seekValue
                    value = ""
                case .inArrayValue:
                    state = .inArray
                    value += char
                default:
                    value += char
                }
            case "]":
                switch(state) {
                case .inValue:
                    // Found value/type pair - store
                    let type = String(value.last!)
                    value = String(value.prefix(value.count - 1))
                    
                    switch(type) {
                    case "%":
                        array.storage.append((value == "true") ? true : false)
                    case "!":
                        array.storage.append(Int(value)!)
                    case "^":
                        array.storage.append(Float(value)!)
                    case "&":
                        array.storage.append(Double(value)!)
                    case "*":
                        array.storage.append(Data(base64Encoded: value)!)
                    default:
                        array.storage.append(ADInstanceDictionary.unescapeValue(value))
                    }
                    
                    state = .seekValue
                    value = ""
                case .seekValue:
                    state = .seekArray
                case .inArrayValue:
                    value += char
                case .inArray:
                    value += char
                    nest -= 1
                    if nest <= 0 {
                        // Convert array and story
                        array.storage.append(ADInstanceArray.decode(value))
                        state = .seekValue
                        value = ""
                    }
                default:
                    value += char
                }
            default:
                switch(state){
                case .seekValue:
                    state = .inValue
                    value = char
                default:
                    value += char
                }
            }
        }
        
        return array
    }
    
    // MARK: - Properties
    /// Stores the name a sub `ADDataTable` used in a one-to-one foreign key relationship with the main table.
    public var subTableName: String = ""
    
    /// Stores the name of the primary key for a sub `ADDataTable` used in a one-to-one foreign key relationship with the main table.
    public var subTablePrimaryKey: String = ""
    
    /// Stores the primary key type for a sub `ADDataTable` used in a one-to-one foreign key relationship with the main table.
    public var subTablePrimaryKeyType: ADDataTableKeyType = .uniqueValue
    
    /// An array of values encoded from the object.
    public var storage: [Any] = []
    
    // MARK: - Functions
    /**
     Converts the `ADInstanceArray` instance to a portable, human-readable string format.
     
     ## Data Types
     The portable, human-readable string format encodes values with a single character _type designator_ as follows:
     
     * `%` - Bool
     * `!` - Int
     * ` - String
     * `^` - Float
     * `&` - Double
     
     Additionally, embedded arrays will be in the `@array[...]` format and embedded dictionaries (`ADInstanceDictionary`) in the `@obj:type<...>` format.
     
     ## Example Output
     
     ```swift
     @array[1!, 2!, 3!, 4!]
     ```
     
     - Returns: A portable, human-readable string representing the array of values.
     */
    public func encode() -> String {
        var result = ""
        var type = "?"
        var val = ""
        
        for value in storage {
            if let dict = value as? ADInstanceDictionary {
                type = ""
                val = dict.encode()
            } else if let array = value as? ADInstanceArray {
                type = ""
                val = array.encode()
            } else if let bool = value as? Bool {
                type = "%"
                val = bool ? "true" : "false"
            } else if let int = value as? Int {
                type = "!"
                val = "\(int)"
            } else if let string = value as? String {
                type = ""
                if string.prefix(4) == "@obj" || string.prefix(7) == "@array[" {
                    val = string
                } else {
                    val = "`\(ADInstanceArray.escapeValue(string))`"
                }
            } else if let float = value as? Float {
                type = "^"
                val = "\(float)"
            } else if let double = value as? Double {
                type = "&"
                val = "\(double)"
            } else if let data = value as? Data {
                type = "*"
                val = "\(data.base64EncodedString())"
            } else {
                type = "?"
                val = "\(value)"
                val = "\(ADInstanceDictionary.escapeValue(val))"
            }
            let pair = "\(val)\(type)"
            if result.isEmpty {
                result = pair
            } else {
                result += ", \(pair)"
            }
        }
        
        return "@array[\(result)]"
    }
}
