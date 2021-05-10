# Action Codable
 
**Action Codable** controls provide support for several common databases and data formats such as SQLite, JSON, XML and CloudKit using Swift 4's new `Codable`, `Encodable` and `Decodable` protocols to move information between your data models and our portable `ADRecord` and `ADRecordSet` formats.

**Action Codable** includes the following elements:

* [ADKey](#ADKey)
* [ADRecord](#ADRecord)
* [ADRecordSet](#ADRecordSet)
* [ADInstanceArray](#ADInstanceArray)
* [ADInstanceDictionary](#ADInstanceDictionary)
* [ADEncodingStorage](#ADEncodingStorage)
* [ADDecodingStorage](#ADDecodingStorage)
* [SQLite](#SQLite)
* [SPON](#SPON)

## Shared Elements

These are common elements shared across all custom coders in the **Action Codable** suite.

<a name="ADKey"></a>
### ADKey

Defines a Coding Key for use when providing a custom Coder for Action Data types. This includes the standard key used for a "super encoder", a string value used for path type keys (KeyedEncodingContainers) and an integer value used for index type keys (UnkeyedEncodingContainers).

<a name="ADRecord"></a>
### ADRecord

Defines a `ADRecord` as a dictionary of **Key/Value** pairs where the **Key** is a `String` and the **Value** is `Any` type. A `ADRecord` can be returned from or sent to a `ADDataProvider` or any of the **Action Codable** controls.
 
#### Example:
 
```swift
let provider = ADSQLiteProvider.shared
let record = try provider.query("SELECT * FROM Categories WHERE id = ?", withParameters: [1])
print(record["name"])
```

<a name="ADRecordSet"></a>
### ADRecordSet

Defines an array of `ADRecord` instances that can be sent to or returned from a `ADDataProvider` or any of the **Action Codable** controls.
 
#### Example:

```swift
let provider = ADSQLiteProvider.shared
let records = try provider.getRows(Category.self)
 
for record in records {
 print(record["name"])
}
```

<a name="ADInstanceArray"></a>
### ADInstanceArray

Defines a passable array of values used as temporary storage when encoding or decoding an Action Data class. `ADInstanceArray` also introduces support for the new **Swift Portable Object Notation** (SPON) data format that allows complex data models to be encoded in a portable text string that encodes not only property keys and data, but also includes type information about the encoded data. For example:
 
```
@array[1!,2!,3!,4!]
```
The portable, human-readable string format encodes values with a single character _type designator_ as follows:
 
* `%` - Bool
* `!` - Int
* `$` - String
* `^` - Float
* `&` - Double
* `*` - Embedded `NSData` or `Data` value
 
 Additionally, embedded arrays will be in the `@array[...]` format and embedded dictionaries in the `@obj:type<...>` format.

<a name="ADInstanceDictionary"></a>
### ADInstanceDictionary

Defines a passable dictionary of `ADRecord` values when encoding or decoding an Action Data class instance. `ADInstanceDictionary` also introduces support for the new **Swift Portable Object Notation** (SPON) data format that allows complex data models to be encoded in a portable text string that encodes not only property keys and data, but also includes type information about the encoded data. For example:
 
```
@obj:Address<state$=`TX` city$=`Seabrook` addr1$=`25 Nasa Rd 1` zip$=`77586` addr2$=`Apt #123`>
```
The portable, human-readable string format encodes values with a single character _type designator_ as follows:
 
* `%` - Bool
* `!` - Int
* `$` - String
* `^` - Float
* `&` - Double
* `*` - Embedded `NSData` or `Data` value
 
 Additionally, embedded arrays will be in the `@array[...]` format and embedded dictionaries in the `@obj:type<...>` format.

<a name="ADEncodingStorage"></a>
### ADEncodingStorage

Holds information about a given Action Data class while it is being encoded.

<a name="ADDecodingStorage"></a>
### ADDecodingStorage

Holds information about a given Action Data object while it is being decoded.

<a name="SQLite"></a>
### SQLite

Contains the custom encoder and decoder to preprocess and post process data object models that will be sent to or returned from a `ADSQLiteProvider` and store or returned from a backing SQLite database.

A `ADSQLEncoder` can return a `ADRecord`, `ADInstanceArray` or `ADInstanceDictionary` representing a given data object model or collection of object models.

A `ADSQLDecoder` takes a `ADRecord`, `ADInstanceArray` or `ADInstanceDictionary` returned from a data source and converts it into a data object model or a collection of object models representing the given information.

<a name="SPON"></a>
### SPON

Contains the custom encoder and decoder to preprocess and post process data object models that will be sent to or returned from a `ADSPONProvider` and store or returned from a backing Swift Portable Object Notation (SPON) database.

A `ADSPONEncoder` can return a `ADRecord`, `ADInstanceArray` or `ADInstanceDictionary` representing a given data object model or collection of object models.

A `ADSPONDecoder` takes a `ADRecord`, `ADInstanceArray` or `ADInstanceDictionary` returned from a data source and converts it into a data object model or a collection of object models representing the given information.

