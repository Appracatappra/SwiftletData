//
//  ADDecodingStorage.swift
//  CoderPlayground
//
//  Created by Kevin Mullins on 9/27/17.
//  Copyright © 2017 Appracatappra, LLC. All rights reserved.
//

import Foundation

/// Holds information about a given Action Data object while it is being decoded.
class ADDecodingStorage {
    
    // MARK: - Properties
    /// An array of items to be decoded.
    var containers: [Any] = []
    
    /// The number of items waiting to be decoded.
    var count: Int {
        return containers.count
    }
    
    /// The next item waiting to be decoded.
    var topContainer: Any {
        precondition(self.containers.count > 0, "Empty container stack.")
        return containers.last!
    }
    
    // MARK: - Initializers
    /// Initializes a `ADDecodingStorage` instance.
    init() {
        
    }
    
    // MARK: - Functions
    /// Pushes the given item into the collection of items waiting to be decoded.
    /// - Parameter container: The item to add to the collection.
    func push(container: Any) {
        containers.append(container)
    }
    
    /// Removes and returns the next item waiting to be decoded.
    /// - Returns: The next item to decode.
    func popContainer() {
        precondition(self.containers.count > 0, "Empty container stack.")
        containers.removeLast()
    }
}
