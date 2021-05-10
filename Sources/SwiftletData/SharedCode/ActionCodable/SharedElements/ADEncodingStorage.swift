//
//  ADSQLEncodingStorage.swift
//  CoderPlayground
//
//  Created by Kevin Mullins on 9/22/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/// Holds information about a given Action Data class while it is being encoded.
class ADEncodingStorage {
    
    // MARK: - Public Properties
    /// An array of elements that have already been encoded.
    var containers: [Any] = []
    
    /// The number of encoded elements stored.
    var count: Int {
        return containers.count
    }
    
    /// Holds the type of the object being encoded. This is used to include the type in sub objects and dictionaries so it can be included in the Swift Portable Object Notation (SPON) output.
    var typeName: String = ""
    
    // MARK: - Public Functions
    /// Creates a new `ADInstanceDictionary` instance, adds it to the collection of containers and returns the new dictionary.
    /// - Returns: A `ADInstanceDictionary` instance.
    func pushKeyedContainer() -> ADInstanceDictionary {
        let dictionary = ADInstanceDictionary()
        dictionary.typeName = typeName
        containers.append(dictionary)
        return dictionary
    }
    
    /// Creates a new `ADInstanceArray` instance, adds it to the collection of containers and returns the new array.
    /// - Returns: A `ADInstanceArray` instance.
    func pushUnkeyedContainer() -> ADInstanceArray {
        let array = ADInstanceArray()
        self.containers.append(array)
        return array
    }
    
    /// Adds the given item to the collection of containers.
    /// - Parameter container: The object instance to add to the collection.
    func push(container: Any) {
        self.containers.append(container)
    }
    
    /// Removes the last item from the collection and returns it.
    /// - Returns: The last item that was in the container collection.
    func popContainer() -> Any {
        precondition(self.containers.count > 0, "Empty container stack.")
        return self.containers.popLast()!
    }
}
