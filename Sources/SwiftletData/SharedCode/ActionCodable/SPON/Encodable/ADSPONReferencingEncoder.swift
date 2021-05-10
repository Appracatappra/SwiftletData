//
//  ADSPONReferencingEncoder.swift
//  ActionControls
//
//  Created by Kevin Mullins on 10/13/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/// A ReferencingEncoder used to store sub class values while encoding an object. The data will be stored directly in the `ADEncodingStorage` during the encoding process.
class ADSPONReferencingEncoder: ADSPONEncoder {
    
    /// The type of container we're referencing.
    private enum Reference {
        /// Referencing a specific index in an array container.
        case array(ADInstanceArray, Int)
        
        /// Referencing a specific key in a dictionary container.
        case dictionary(ADInstanceDictionary, String)
    }
    
    /// Hold an instance of the encoder.
    var encoder: ADSPONEncoder
    
    /// Holds a reference to the object being encoded.
    private var reference: Reference
    
    /**
     Initializes an instance of the `ADSQLReferencingEncoder` and sets its initial properties.
     - Paramaters:
         - encoder: The base `ADSPONEncoder`.
         - index: The array index for the object being encoded.
         - array: The array being encoded.
     */
    init(referencing encoder: ADSPONEncoder, at index: Int, wrapping array: ADInstanceArray) {
        self.encoder = encoder
        self.reference = .array(array, index)
        super.init()
        
        // FIXME: Keypath
        // Disabled key path here seems to fix issue with encoding sub containers.
        //self.codingPath.append(ADKey(intValue: index)!)
    }
    
    /**
     Initializes an instance of the `ADSQLReferencingEncoder` and sets its initial properties.
     - Paramaters:
         - encoder: The base `ADSPONEncoder`.
         - key: The key for the dictionary item being encoded.
         - dictionary: The `ADInstanceDictionary` being encoded.
     */
    init(referencing encoder: ADSPONEncoder, at key: CodingKey, wrapping dictionary: ADInstanceDictionary) {
        self.encoder = encoder
        self.reference = .dictionary(dictionary, key.stringValue)
        super.init()
        
        // FIXME: Keypath
        // Disabled key path here seems to fix issue with encoding sub containers.
        //self.codingPath.append(key) // TODO - Might need more params here
    }
    
    /**
     Deinitialize the object and clean-up memory before disposing.
     */
    deinit {
        let value: Any
        switch self.storage.count {
        case 0:
            value = ADRecord()
        case 1:
            value = self.storage.popContainer()
        default:
            fatalError("Referencing encoder deallocated with multiple containers on stack.")
        }
        
        switch self.reference {
        case .array(let array, let index):
            array.storage.insert(value, at: index)
            
        case .dictionary(let dictionary, let key):
            dictionary.storage[key] = value
        }
    }
}
