# Shared Elements

Contains the elements shared across all **Action Data Providers** such as `ADColumnSchema`, `ADTableSchema` and `ADCrossReference`.

This includes the following classes:

* [ADColumnSchema](#ADColumnSchema)
* [ADTableSchema](#ADTableSchema)
* [ADCrossReference](#ADCrossReference)
* [ADTableStore](#ADTableStore)
* [ADDataStore](#ADDataStore)
* [ADUtilities](#ADUtilities)

<a name="ADColumnSchema"></a>
## ADColumnSchema

Holds all of the schema information about a table schema's columns as read from a backing data store. This includes the following:

* **id** - The column's unique ID.
* **name** - The column's name.
* **type** - The column's SQL data type such as `TEXT`, `BOOLEAN`, `DATE`, etc.
* **allowsNull** - `true` if the value of this column can be `null`, else `false`. This is the same as Swift's `nil` instance.
* **defaultValue** - The default value for this column if no value is provided during an `INSERT` or `UPDATE` operation.
* **isPrimaryKey** - `true` if this column is the table's primary key.
* **autoIncrement** - `true` if the column is a `INTEGER` value that is auto incremented by the database.
* **checkExpression** - An expression that is used to valid the data stored in the column.

<a name="ADTableSchema"></a>
## ADTableSchema

Holds all the information about a table's schema as read from a backing data store. This includes the following:

* **name** - The table's name.
* **columns** - The table's column information as an array of `ADColumnSchema` instances.

<a name="ADCrossReference"></a>
## ADCrossReference

Creates and maintains a one-to-many or many-to-many cross reference relationship between two `ADDataTable` instances that can be stored in or read from a `ADDataProvider`.
 
### Example:
The following creates a relationship between the `Group` and `Person` tables (both conforming to `ADDataTable`) on the `Group.people` property:
 
```swift
import Foundation
import ActionData
 
class Group: ADDataTable {
	 
	static var tableName = "Groups"
	static var primaryKey = "id"
	static var primaryKeyType: ADDataTableKeyType = .computedInt
	 
	var id = ADSQLiteProvider.shared.makeID(Group.self) as! Int
	var name = ""
	var people = ADCrossReference<Person>(name: "PeopleInGroup", leftKeyName: "groupID", rightKeyName: "personID")
	 
	required init() {
 
	}
}
```
Instance of the `Person` table stored in `people` will be cross referenced in the `PeopleInGroup` table where `groupID` is the `Group` instance's `id` and `personID` is the `Person` instances `id`.
 
> ⚠️ **Warning**: `ADCrossReference` was meant to work with a small number of relationships **only**, because all cross referenced items are always read into memory when the parent object is loaded. Care should be taken to keep from overflowing memory.

<a name="ADTableStore"></a>
## ADTableStore

Represents an in-memory SQL Data Store table used to hold both the table's schema and the data it represents.

> ⚠️ **Warning**: Since a `ADTableStore` holds all data in-memory, care should be taken not to overload memory. As a result, an `ADTableStore` is not a good choice for working with large amounts of data.

<a name="ADDataStore"></a>
## ADDataStore

Represents an in-memory Data Store used to provide SQL ability to data sources that typically do not support SQL (such as JSON or XML). `ADDataStore` works with `ADTableStore` to define both the structure of the tables and to contain the rows of data stored in each table. `ADDataStore` understands a subset of the full SQL instruction set (as known by SQLite).

Use the `execute` method to execute non-query SQL statements against the Data Store. For example:

 ```swift
 let datastore = ADDataStore()
 
 var sql = """
 CREATE TABLE IF NOT EXISTS parts
 (
     part_id           INTEGER   PRIMARY KEY AUTOINCREMENT,
     stock             INTEGER   DEFAULT 0   NOT NULL,
     name              TEXT,
     description       TEXT      CHECK( description != '' ),    -- empty strings not allowed
     available         BOOL      DEFAULT true
 );
 """
 
 try datastore.execute(sql)
 ```
 
 Use the `query` method to execute query SQL statements and return rows matching the result. For example:
 
 ```swift
 let results = try datastore.query("SELECT * FROM parts")
 print(results)
 ```
 
 > ⚠️ **Warning**: Since a `ADDataStore` holds all data in-memory, care should be taken not to overload memory. As a result, an `ADDataStore` is not a good choice for working with large amounts of data.
 
<a name="ADUtilities"></a>
## ADUtilities

Defines a set of utilities to handle data related issues such as comparing two values of type `Any`. This includes the following functions:

* **compare** - Compares two values of type `Any` to see if they are equal, not equal, less than, greater than, less than or equal to or greater than or equal to each other. Both values must be of the same type and internally stored as a **Int**, **Double**, **Float**, **String** or **Bool**.
* **compute** - Calculates the addition, subtraction, multiplication or division of two values of type `Any`. Both values must be of the same type and internally stored as a **Int**, **Double**, **Float**, **String** or **Bool**. **String** and **Bool** types support addition only. Additionally, **String** can be added to any other type and the result is a **String** with the value appended to it.
* **cast** - Attempts to cast the given `Any` type value to the given SQL Database type.