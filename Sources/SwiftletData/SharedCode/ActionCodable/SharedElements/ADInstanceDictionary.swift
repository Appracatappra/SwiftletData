//
//  ADInstanceDictionary.swift
//  CoderPlayground
//
//  Created by Kevin Mullins on 9/26/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/**
 Defines a passable dictionary of `ADRecord` values when encoding or decoding an Action Data class instance. `ADInstanceDictionary` also introduces support for the new **Swift Portable Object Notation** (SPON) data format that allows complex data models to be encoded in a portable text string that encodes not only property keys and data, but also includes type information about the encoded data. For example:
 
 ## Example:
 ```swift
 let data = "@obj:Rectangle<left!=`0` bottom!=`0` right!=`0` top!=`0`>"
 let dictionary = ADInstanceDictionary.decode(data)
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
public class ADInstanceDictionary {
    
    // MARK: - Enumerations
    /// Defines the current parse state when decoding a string representation of the array.
    private enum parserState {
        /// Seeking the start of an dictionary definition.
        case seekDictionary
        
        /// When seeking the start of the dictionary a ":" has been found the parser has been collecting the type of the values stored in the dictionary.
        case inValueType
        
        /// Seeking the start of a key.
        case seekKey
        
        /// Assembling a key.
        case inKey
        
        /// Seeking the start of a value.
        case seekValue
        
        /// Assembling a value.
        case inValue
        
        /// Inside an embedded dictionary.
        case inDictionary
        
        /// Inside an embedded dictionary value.
        case inDictionaryValue
        
        /// Inside an embedded array.
        case inArray
        
        /// Inside an embedded array value.
        case inArrayValue
    }
    
    // MARK: - Static Functions
    /**
     Converts a given value into a format that can be safely stored in an `ADInstanceDictionary` portable, human-readable string format.
     
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
     Takes a `ADInstanceDictionary` object stored in a portable, human-readable string format and converts it to a dictionary of the original values.
     
     ## Example:
     ```swift
     let data = "@obj:Rectangle<left!=`0` bottom!=`0` right!=`0` top!=`0`>"
     let dictionary = ADInstanceDictionary.decode(data)
     ```
     
     ## Data Types
     The portable, human-readable string format encodes values with a single character _type designator_ as follows:
     
     * `%` - Bool
     * `!` - Int
     * `$` - String
     * `^` - Float
     * `&` - Double
     * `*` - `NSData` or `Data` as a base 64 encoded string
     
     Additionally, embedded arrays (`ADInstanceArray`) will be in the `@array[...]` format and embedded dictionaries (`ADInstanceDictionary`) in the `@obj:type<...>` format.
     
     - Parameter text: The string in the portable, human-readable string format.
     - Returns: An instance dictionary of the original Swift object values.
     */
    public static func decode(_ text: String) -> ADInstanceDictionary {
        let dictionary = ADInstanceDictionary()
        var state: parserState = .seekDictionary
        var value = ""
        var key = ""
        var nest = 0
        
        for c in text {
            let char = String(c)
            
            switch(char) {
            case ":":
                switch(state) {
                case .seekDictionary:
                    value = ""
                    state = .inValueType
                default:
                   value += char
                }
            case "<":
                switch(state) {
                case .seekDictionary:
                    state = .seekKey
                case .inValueType:
                    dictionary.typeName = value
                    value = ""
                    state = .seekKey
                case .seekValue:
                    state = .inDictionary
                    nest = 1
                    value += char
                case .inDictionary:
                    nest += 1
                    value += char
                default:
                    value += char
                }
            case "[":
                switch(state) {
                case .seekValue:
                    state = .inArray
                    nest = 1
                    value = char
                case .inArray:
                    nest += 1
                    value += char 
                default:
                    value += char
                }
            case "]":
                switch(state) {
                case .seekValue:
                    state = .seekKey
                case .inArrayValue:
                    value += char
                case .inArray:
                    value += char
                    nest -= 1
                    if nest <= 0 {
                        // Convert array and story
                        dictionary.storage[key] = ADInstanceArray.decode(value)
                        state = .seekKey
                        value = ""
                    }
                default:
                    value += char
                }
            case " ":
                switch(state) {
                case .seekKey:
                    // Ignore white spaces until key found
                    break
                case .inKey:
                    state = .seekValue
                case .seekValue:
                    break
                default:
                    value += char
                }
            case "=":
                switch(state) {
                case .inKey:
                    state = .seekValue
                case .seekValue:
                    break
                default:
                    value += char
                }
            case "`":
                switch(state) {
                case .seekValue:
                    state = .inValue
                    value = ""
                case .inValue:
                    // Found key/value pair - store
                    let type = String(key.last!)
                    key = String(key.prefix(key.count - 1))
                    
                    switch(type) {
                    case "%":
                        dictionary.storage[key] = (value == "true") ? true : false
                    case "!":
                        dictionary.storage[key] = Int(value)
                    case "^":
                        dictionary.storage[key] = Float(value)
                    case "&":
                        dictionary.storage[key] = Double(value)
                    case "*":
                        dictionary.storage[key] = Data(base64Encoded: value)
                    default:
                        dictionary.storage[key] = ADInstanceDictionary.unescapeValue(value)
                    }
                    
                    state = .seekKey
                    value = ""
                case .inDictionary:
                    state = .inDictionaryValue
                    value += char
                case .inDictionaryValue:
                    state = .inDictionary
                    value += char
                default:
                    value += char
                }
            case ">":
                switch(state) {
                case .seekKey:
                    state = .seekDictionary
                case .inDictionaryValue:
                    value += char
                case .inDictionary:
                    value += char
                    nest -= 1
                    if nest <= 0 {
                        // Convert dictionary and story
                        dictionary.storage[key] = ADInstanceDictionary.decode(value)
                        state = .seekKey
                        value = ""
                    }
                default:
                    value += char
                }
            default:
                switch(state){
                case .seekKey:
                    state = .inKey
                    key = char
                case .inKey:
                    key += char
                default:
                    value += char
                }
            }
        }
        
        return dictionary
    }
    
    // MARK: - Properties
    /// Stores the name a sub `ADDataTable` used in a one-to-one foreign key relationship with the main table.
    public var subTableName: String = ""
    
    /// Stores the name of the primary key for a sub `ADDataTable` used in a one-to-one foreign key relationship with the main table.
    public var subTablePrimaryKey: String = ""
    
    /// Stores the primary key type for a sub `ADDataTable` used in a one-to-one foreign key relationship with the main table.
    public var subTablePrimaryKeyType: ADDataTableKeyType = .uniqueValue
    
    /// A dictionary of key/value pairs from the coded object.
    public var storage: ADRecord = ADRecord()
    
    /// The name of the type of object being encoded in the dictionary
    public var typeName: String = ""
    
    // MARK: - Functions
    /**
     Converts the `ADInstanceDictionary` instance to a portable, human-readable string format.
     
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
     @obj:Appearance<borderWidth!=`1` fillColor$=`#FFFFFF` textColor$=`#FFFFFF` borderColor$=`#FFFFFF` hasBorder%=`true` placement=@obj:Rectangle<left!=`0` bottom!=`0` right!=`0` top!=`0`>>
     ```
     
     - Returns: A portable, human-readable string representing the dictionary of values.
     */
    public func encode() -> String {
        var result = ""
        var type = "?"
        var val = ""
        var valueType = ""
        
        // Working with a contained dictionary?
        if typeName.contains("Dictionary") {
            // Find the base type of the stored value
            valueType = typeName.components(separatedBy: ", ").last!
            valueType = valueType.replacingOccurrences(of: ")", with: "")
            typeName = "Dictionary"
        }
        let name = (typeName.isEmpty) ? "" : ":\(typeName)"
        
        for (key, value) in storage {
            if let dict = value as? ADInstanceDictionary {
                type = ""
                if dict.typeName.isEmpty {
                    dict.typeName = valueType
                }
                val = dict.encode()
            } else if let array = value as? ADInstanceArray {
                type = ""
                val = array.encode()
            } else if let bool = value as? Bool {
                type = "%"
                val = bool ? "`true`" : "`false`"
            } else if let int = value as? Int {
                type = "!"
                val = "`\(int)`"
            } else if let string = value as? String {
                if string.prefix(4) == "@obj" || string.prefix(7) == "@array[" {
                    type = ""
                    val = string
                } else {
                    type = "$"
                    val = "`\(ADInstanceDictionary.escapeValue(string))`"
                }
            } else if let float = value as? Float {
                type = "^"
                val = "`\(float)`"
            } else if let double = value as? Double {
                type = "&"
                val = "`\(double)`"
            } else if let data = value as? Data {
                type = "*"
                val = "`\(data.base64EncodedString())`"
            } else {
                type = "?"
                val = "\(value)"
                val = "`\(ADInstanceDictionary.escapeValue(val))`"
            }
            let pair = "\(key)\(type)=\(val)"
            if result.isEmpty {
                result = pair
            } else {
                result += " \(pair)"
            }
        }
        
        return "@obj\(name)<\(result)>"
    }
}
