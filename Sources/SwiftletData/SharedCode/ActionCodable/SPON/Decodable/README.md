# Decodable

Contains all of the routines needed to post process data returned from a `ADSPONiteProvider` and convert it back to Swift objects.

This includes the following classes:

* [ADSPONDecoder](#ADSPONDecoder)
* [ADSPONKeyedDecodingContainer](#ADSPONKeyedDecodingContainer)
* [ADSPONUnkeyedDecodingContainer](#ADSPONUnkeyedDecodingContainer)
* [ADSPONSingleValueDecodingContainer](#ADSPONSingleValueDecodingContainer)

<a name="ADSPONDecoder"></a>
## ADSPONDecoder

Decodes a `Codable` or `Decodable` class from a `ADRecord` read from a SQLite database using a `ADSPONiteProvider`. The result is an instance of the class with the properties set from the database record. This decoder will automatically handle `URLs` and `Enums` (if the Enum is value based and also marked `Codable` or `Decodable`).

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

let decoder = ADSPONDecoder()
let category2 = try decoder.decode(Category.self, from: data)
```

### Remark:
To retrieve `UIColors` in the record use the `String.uiColor` extension property and to retrieve `UIImages` use the `String.uiImage` extension property.

<a name="ADSPONKeyedDecodingContainer"></a>
## ADSPONKeyedDecodingContainer

A KeyedDecodingContainer used to read key/value pairs while decoding an object. The data will be stored in a `ADInstanceDictionary` during the decoding process.

<a name="ADSPONUnkeyedDecodingContainer"></a>
## ADSPONUnkeyedDecodingContainer

A UnkeyedDecodingContainer used to read arrays while decoding an object. The data will be stored in a `ADInstanceArray` during the decoding process.

<a name="ADSPONSingleValueDecodingContainer"></a>
## ADSPONSingleValueDecodingContainer

A SingleValueDecodingContainer used to read individual values while decoding an object. The data will be stored directly in the `ADDecodingStorage` during the decoding process.
