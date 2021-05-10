## Protocols

Contains the protocols shared across all **Action Data Providers** such as `ADDataProvider`, `ADDataTable` and `ADDataCrossReference`.

This includes the following:

* [ADDataProvider](#ADDataProvider)
* [ADDataTable](#ADDataTable)
* [ADDataCrossReference](#ADDataCrossReference)

<a name="ADDataProvider"></a>
## ADDataProvider

Defines an **Action Data Provider** that can be used to read and write data from a given data source.

A `ADDataProvider` provides both light-weight, low-level access to data stored in a SQLite database and high-level access via a Object Relationship Management (ORM) model. Use provided functions to read and write data stored in a `ADRecord` format from and to the database using SQL statements directly.
 
### Example:
```swift
let provider = ADDataProvider()
let record = try provider.query("SELECT * FROM Categories WHERE id = ?", withParameters: [1])
print(record["name"])
```
 
Optionally, pass a class instance conforming to the `ADDataTable` protocol to the `ADSQLiteProvider` and it will automatically handle reading, writing and deleting data as required.
 
### Example:
```swift
let addr1 = Address(addr1: "PO Box 1234", addr2: "", city: "Houston", state: "TX", zip: "77012")
let addr2 = Address(addr1: "25 Nasa Rd 1", addr2: "Apt #123", city: "Seabrook", state: "TX", zip: "77586")
 
let p1 = Person(firstName: "John", lastName: "Doe", addresses: ["home":addr1, "work":addr2])
let p2 = Person(firstName: "Sue", lastName: "Smith", addresses: ["home":addr1, "work":addr2])
 
let group = Group(name: "Employees", people: [p1, p2])
try provider.save(group)
```

<a name="ADDataProvider"></a>
## ADDataTable

A class conforming to this protocol defines a unique container that holds the data that can be read from or written to a `ADDataProvider` source. For example, a `ADDataTable` can be used represent a SQLite database table, a JSON node or a XML node.
 
Besides acting as a model for the physical representation of the data within the given data source (as defined by a `ADDataProvider`), an instance of a class conforming to this protocol will act as an individual "row" of data stored within the data source.
 
## Example:
```swift
import Foundation
import ActionUtilities
import ActionData
 
class Category: ADDataTable {
	 
	enum CategoryType: String, Codable {
		case local
		case web
	}
	
	// Provides conformance to `ADDataTable` and provides the name
	// of the table, the name of the primary key and the type of
	// primary key.
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
```

> ⚠️ **Warning:** A class or struct conforming to this protocol **must** contain a property with the same name as the `primaryKey` value. Failing to do so will result in an error.

<a name="ADDataCrossReference"></a>
## ADDataCrossReference

A class or struct conforming to this protocol can be used to store a one-to-many or many-to-many relationship between `ADDataTable` records stored in or read from a `ADDataProvider` instance.

```swift
import Foundation
import ActionUtilities
import ActionData

struct Address: Codable {
    var addr1 = ""
    var addr2 = ""
    var city = ""
    var state = ""
    var zip = ""
}

class Person: ADDataTable {
    
    static var tableName = "People"
    static var primaryKey = "id"
    static var primaryKeyType = ADDataTableKeyType.autoUUIDString
    
    var id = UUID().uuidString
    var firstName = ""
    var lastName = ""
    var addresses: [String:Address] = [:]
    
    required init() {
        
    }
    
    init(firstName: String, lastName:String, addresses: [String:Address] = [:]) {
        self.firstName = firstName
        self.lastName = lastName
        self.addresses = addresses
    }
}

class Group: ADDataTable {
    
    static var tableName = "Groups"
    static var primaryKey = "id"
    static var primaryKeyType = ADDataTableKeyType.autoUUIDString
    
    var id = UUID().uuidString
    var name = ""
    var people = ADCrossReference<Person>(name: "PeopleInGroup", leftKeyName: "groupID", rightKeyName: "personID")
    
    required init() {
        
    }
    
    init(name: String, people: [Person] = []) {
        self.name = name
        self.people.storage = people
    }
}
```
