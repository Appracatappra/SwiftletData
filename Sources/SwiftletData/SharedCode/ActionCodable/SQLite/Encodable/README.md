# Encodable

Contains all of the routines needed to preprocess data that will be sent to a `ADSQLiteProvider`.

This includes the following classes:

* [ADSQLEncoder](#ADSQLEncoder)
* [ADSQLKeyedEncodingContainer](#ADSQLKeyedEncodingContainer)
* [ADSQLUnkeyedEncodingContainer](#ADSQLUnkeyedEncodingContainer)
* [ADSQLSingleValueEncodingContainer](#ADSQLSingleValueEncodingContainer)
* [ADSQLReferencingEncoder](#ADSQLReferencingEncoder)

<a name=""></a>
## ADSQLEncoder

Encodes a `Codable` or `Encodable` class into a `ADRecord` that can be written into a SQLite database using a `ADSQLiteProvider`. The result is a dictionary of key/value pairs representing the data currently stored in the class. This encoder will automatically handle `URLs` and `Enums` (if the Enum is value based and also marked `Codable` or `Encodable`).
 
### Example:
```swift
import ActionUtilities
import ActionData

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
```
 
###Remark: 

To store `UIColors` in the record use the `toHex()` extension method and to store `UIImages` use the `toData()` extension method.

<a name="ADSQLKeyedEncodingContainer"></a>
## ADSQLKeyedEncodingContainer

A KeyedEncodingContainer used to store key/value pairs while encoding an object. The data will be stored in a `ADInstanceDictionary` during the encoding process.

<a name="ADSQLUnkeyedEncodingContainer"></a>
## ADSQLUnkeyedEncodingContainer

A UnkeyedEncodingContainer used to store arrays while encoding an object. The data will be stored in a `ADInstanceArray` during the encoding process.

<a name="ADSQLSingleValueEncodingContainer"></a>
## ADSQLSingleValueEncodingContainer

A SingleValueEncodingContainer used to store individual values while encoding an object. The data will be stored directly in the `ADEncodingStorage` during the encoding process.

<a name="ADSQLReferencingEncoder"></a>
## ADSQLReferencingEncoder

A ReferencingEncoder used to store sub class values while encoding an object. The data will be stored directly in the `ADEncodingStorage` during the encoding process.

