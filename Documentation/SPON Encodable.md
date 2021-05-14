# Encodable

Contains all of the routines needed to preprocess data that will be sent to a `ADSPONiteProvider`.

This includes the following classes:

* [ADSPONEncoder](#ADSPONEncoder)
* [ADSPONKeyedEncodingContainer](#ADSPONKeyedEncodingContainer)
* [ADSPONUnkeyedEncodingContainer](#ADSPONUnkeyedEncodingContainer)
* [ADSPONSingleValueEncodingContainer](#ADSPONSingleValueEncodingContainer)
* [ADSPONReferencingEncoder](#ADSPONReferencingEncoder)

<a name=""></a>
## ADSPONEncoder

Encodes a `Codable` or `Encodable` class into a `ADRecord` that can be written into a SQLite database using a `ADSPONiteProvider`. The result is a dictionary of key/value pairs representing the data currently stored in the class. This encoder will automatically handle `URLs` and `Enums` (if the Enum is value based and also marked `Codable` or `Encodable`).

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

let encoder = ADSPONEncoder()
let category = Category()
let data = try encoder.encode(category)
```

###Remark:

To store `UIColors` in the record use the `toHex()` extension method and to store `UIImages` use the `toData()` extension method.

<a name="ADSPONKeyedEncodingContainer"></a>
## ADSPONKeyedEncodingContainer

A KeyedEncodingContainer used to store key/value pairs while encoding an object. The data will be stored in a `ADInstanceDictionary` during the encoding process.

<a name="ADSPONUnkeyedEncodingContainer"></a>
## ADSPONUnkeyedEncodingContainer

A UnkeyedEncodingContainer used to store arrays while encoding an object. The data will be stored in a `ADInstanceArray` during the encoding process.

<a name="ADSPONSingleValueEncodingContainer"></a>
## ADSPONSingleValueEncodingContainer

A SingleValueEncodingContainer used to store individual values while encoding an object. The data will be stored directly in the `ADEncodingStorage` during the encoding process.

<a name="ADSPONReferencingEncoder"></a>
## ADSPONReferencingEncoder

A ReferencingEncoder used to store sub class values while encoding an object. The data will be stored directly in the `ADEncodingStorage` during the encoding process.

