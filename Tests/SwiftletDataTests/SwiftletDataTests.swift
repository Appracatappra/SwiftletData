//
//  SwiftletDataTests.swift
//  
//
//  Created by Kevin Mullins on 5/14/21.
//

import XCTest
import SwiftUI
@testable import SwiftletData

final class SwiftUtilitiesTests: XCTestCase {
    
    class Category: ADDataTable {
        
        enum CategoryType: String, Codable {
            case local
            case web
        }
        
        static var tableName = "Categories"
        static var primaryKey = "id"
        static var primaryKeyType: ADDataTableKeyType = .computedInt
        
        var id = 0
        var name = ""
        var type: CategoryType = .local
        
        required init() {
            
        }
        
        init(id:Int = 0, name:String = "", type:CategoryType = .local) {
            
        }
    }
    
    func testSPON() {
        let category = Category(id: 1, name: "Appracatappra.com", type: .web)
        let encoder = ADSPONEncoder()
        let decoder = ADSPONDecoder()
        
        do {
            let value = try encoder.encode(category)
            let rebuilt = try decoder.decode(Category.self, from: value)
            XCTAssert(category.name == rebuilt.name)
        } catch {
            XCTFail()
            print("SPON failed: \(error)")
        }
    }
    
}
