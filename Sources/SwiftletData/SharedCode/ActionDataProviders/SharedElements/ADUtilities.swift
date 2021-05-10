//
//  ADUtilities.swift
//  ActionControls
//
//  Created by Kevin Mullins on 11/9/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation
import SwiftUI
import SwiftletUtilities

/**
 Defines a set of utilities to handle data related issues such as comparing two values of type `Any`.
 */
public class ADUtilities {
    
    /// Defines a comparison between two values.
    public enum Comparison {
        /// Both values are equal.
        case equalTo
        
        /// The values are not equal.
        case notEqualTo
        
        /// The first value is less than the second.
        case lessThan
        
        /// The first value is greater than the second.
        case greaterThan
        
        /// The first value is less than or equal to the second one.
        case lessThanOrEqualTo
        
        /// The first value is greater than or equal to the second one.
        case greaterThanOrEqualTo
        
        /// The second value is contained inside the first.
        case contains
        
        /// Testing to see if both values are `true`.
        case and
        
        /// Testing to see if either value is `true`.
        case or
    }
    
    /// Defines a computation between values.
    public enum Operation {
        /// Adding two values.
        case plus
        
        /// Subtracting one value from another.
        case minus
        
        /// Multiplying two values.
        case times
        
        /// Dividing a value by another.
        case dividedBy
    }
    
    /**
     Compares two values of type `Any` to see if they are equal, not equal, less than, greater than, less than or equal to or greater than or equal to eachother. Both values must be of the same type and internally stored as a **Int**, **Double**, **Float**, **String** or **Bool**.
     
     - Parameters:
         - left: The first value to compare.
         - comparison: The comparison to perform between the two values as equal, not equal, less than, greater than, less than or equal to or greater than or equal to.
         - right: The second value to compare.
     - Returns: `true` if the two values are equal, not equal, less than, greater than, less than or equal to or greater than or equal to eachother (based on the requested comparison), else `false`.
    */
    public static func compare(_ left: Any, _ comparison: Comparison, _ right: Any) -> Bool {
        
        // Comparing int values
        if let v1 = left as? Int {
            if let v2 = right as? Int {
                switch comparison {
                case .equalTo:
                    return (v1 == v2)
                case .notEqualTo:
                    return (v1 != v2)
                case .lessThan:
                    return (v1 < v2)
                case .greaterThan:
                    return (v1 > v2)
                case .lessThanOrEqualTo:
                    return (v1 <= v2)
                case .greaterThanOrEqualTo:
                    return (v1 >= v2)
                default:
                    return false
                }
            }
        }
        
        // Comparing double values
        if let v1 = left as? Double {
            if let v2 = right as? Double {
                switch comparison {
                case .equalTo:
                    return (v1 == v2)
                case .notEqualTo:
                    return (v1 != v2)
                case .lessThan:
                    return (v1 < v2)
                case .greaterThan:
                    return (v1 > v2)
                case .lessThanOrEqualTo:
                    return (v1 <= v2)
                case .greaterThanOrEqualTo:
                    return (v1 >= v2)
                default:
                    return false
                }
            }
        }
        
        // Comparing float values
        if let v1 = left as? Float {
            if let v2 = right as? Float {
                switch comparison {
                case .equalTo:
                    return (v1 == v2)
                case .notEqualTo:
                    return (v1 != v2)
                case .lessThan:
                    return (v1 < v2)
                case .greaterThan:
                    return (v1 > v2)
                case .lessThanOrEqualTo:
                    return (v1 <= v2)
                case .greaterThanOrEqualTo:
                    return (v1 >= v2)
                default:
                    return false
                }
            }
        }
        
        // Comparing string values
        if let v1 = left as? String {
            if let v2 = right as? String {
                switch comparison {
                case .equalTo:
                    return (v1 == v2)
                case .notEqualTo:
                    return (v1 != v2)
                case .lessThan:
                    return (v1 < v2)
                case .greaterThan:
                    return (v1 > v2)
                case .lessThanOrEqualTo:
                    return (v1 <= v2)
                case .greaterThanOrEqualTo:
                    return (v1 >= v2)
                case .contains:
                    return v1.contains(v2)
                default:
                    return false
                }
            }
        }
        
        // Comparing bool values
        if let v1 = left as? Bool {
            if let v2 = right as? Bool {
                switch comparison {
                case .equalTo:
                    return (v1 == v2)
                case .notEqualTo:
                    return (v1 != v2)
                case .and:
                    return (v1 && v2)
                case .or:
                    return (v1 || v2)
                default:
                    // Invalid operation on two bools
                    return false
                }
            }
        }
        
        // Not equal
        return false
    }
    
    /**
     Calculates the addition, subtraction, multiplication or division of two values of type `Any`. Both values must be of the same type and internally stored as a **Int**, **Double**, **Float**, **String** or **Bool**. **String** and **Bool** types support addition only. Additionally, **String** can be added to any other type and the result is a **String** with the value appended to it.
     
     - Parameters:
         - left: The first value to calculate.
         - operation: The operation to perform as addition, subtraction, multiplication or division.
         - right: The second value to calculate.
     - Returns: The computed value or an error message (as **String**) if the computation is not valid.
     */
    public static func compute(_ left: Any, _ operation: Operation, _ right: Any) -> Any {
        
        // Computing integers?
        if let v1 = left as? Int {
            if let v2 = right as? Int {
                switch operation {
                case .plus:
                    return (v1 + v2)
                case .minus:
                    return (v1 - v2)
                case .times:
                    return (v1 * v2)
                case .dividedBy:
                    if v2 == 0 {
                        return "Error: division by zero."
                    } else {
                        return (v1 / v2)
                    }
                }
            }
            if let v2 = right as? String {
                if operation == .plus {
                    return "\(v1)\(v2)"
                }
            }
        }
        
        // Computing double?
        if let v1 = left as? Double {
            if let v2 = right as? Double {
                switch operation {
                case .plus:
                    return (v1 + v2)
                case .minus:
                    return (v1 - v2)
                case .times:
                    return (v1 * v2)
                case .dividedBy:
                    if v2 == 0 {
                        return "Error: division by zero."
                    } else {
                        return (v1 / v2)
                    }
                }
            }
            if let v2 = right as? String {
                if operation == .plus {
                    return "\(v1)\(v2)"
                }
            }
        }
        
        // Computing float?
        if let v1 = left as? Float {
            if let v2 = right as? Float {
                switch operation {
                case .plus:
                    return (v1 + v2)
                case .minus:
                    return (v1 - v2)
                case .times:
                    return (v1 * v2)
                case .dividedBy:
                    if v2 == 0 {
                        return "Error: division by zero."
                    } else {
                        return (v1 / v2)
                    }
                }
            }
            if let v2 = right as? String {
                if operation == .plus {
                    return "\(v1)\(v2)"
                }
            }
        }
        
        // Computing binary?
        if let v1 = left as? Bool {
            if let v2 = right as? Bool {
                if operation == .plus {
                    return (v1 || v2)
                }
            }
            if let v2 = right as? String {
                if operation == .plus {
                    return "\(v1)\(v2)"
                }
            }
        }
        
        // Computing string?
        if let v1 = left as? String {
            if let v2 = right as? String {
                if operation == .plus {
                    return "\(v1)\(v2)"
                }
            }
            if let v2 = right as? Int {
                if operation == .plus {
                    return "\(v1)\(v2)"
                }
            }
            if let v2 = right as? Double {
                if operation == .plus {
                    return "\(v1)\(v2)"
                }
            }
            if let v2 = right as? Float {
                if operation == .plus {
                    return "\(v1)\(v2)"
                }
            }
            if let v2 = right as? Bool {
                if operation == .plus {
                    return "\(v1)\(v2)"
                }
            }
        }
        
        // Output issue on error
        return "Error: \(left) \(operation) \(right)"
    }
    
    /**
     Attempts to cast the given `Any` type value to the given SQL Database type.
     
     - Parameters:
         - input: The value to convert.
         - type: The SQL database column type to convert the value to.
     - Returns: The value converted to the requested type or throws an error if the type cannot be converted.
    */
    public static func cast(_ input: Any, to type: ADSQLColumnType) throws -> Any {
        
        // Integer cast?
        if let value = input as? Int {
            switch type {
            case .floatType:
                return Float(value)
            case .boolType:
                return (value != 0)
            case .textType:
                return "\(value)"
            case .integerType:
                return value
            default:
                break
            }
        }
        
        // Float cast?
        if let value = input as? Float {
            switch type {
            case .integerType:
                return Int(value)
            case .boolType:
                return (value != 0)
            case .textType:
                return "\(value)"
            case .floatType:
                return value
            default:
                break
            }
        }
        
        // Bool cast?
        if let value = input as? Bool {
            switch type {
            case .integerType:
                return value ? 1 : 0
            case .floatType:
                return value ? 1 : 0
            case .textType:
                return "\(value)"
            case .boolType:
                return value
            default:
                break
            }
        }
        
        // String cast?
        if let value = input as? String {
            switch type {
            case .integerType:
                return Int(value)!
            case .boolType:
                return "true,on,yes,1".contains(value.lowercased())
            case .floatType:
                return Float(value)!
            case .colorType:
                if let color = Color(fromHex: value) {
                    return color
                }
            case .textType:
                return value
            default:
                break
            }
        }
        
        // Color cast
        if let value = input as? Color {
            switch type {
            case .textType:
                // Convert to hex value
                return value.toHex()
            case .colorType:
                return value
            default:
                break
            }
        }
        
        throw ADSQLExecutionError.syntaxError(message: "Unable to cast `\(input)` to \(type).")
    }
}
