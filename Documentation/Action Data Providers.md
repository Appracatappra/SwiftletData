# Action Data Providers

**Action Data Providers** provide light weight, low-level access to several common databases and data formats such as **SQLite**, **SPON** and **CloudKit**. Results are returned as a key/value dictionary (`ADRecord`) or as an array of key/value dictionaries (`ADRecordSet`).

**Action Data Providers** provide a subset of the full SQL query language (using SQLite's syntax) to data sources that typically don't natively understand SQL (such as **CloudKit**). This allows the developer to work in SQL across data sources.

Optionally, an **Action Data Provider** can be used with a set of `Codable` structures or classes to provide high-level **Object Relationship Management** (ORM) with the Data Provider handling adding, updating or deleting the backing records in the Data Source.

The **Action Data Providers** are designed to be interchangeable, so you can start developing locally using a SQLite database and a `ADSQLiteProvider`, then later switch to CloudKit and a `ADiCloudProvider` with minimal code changes.

Additionally, **Action Data Providers** can be used to move data from one source to another. For example, download data from the web in JSON and save it to a local SQLite database using a `ADSQLiteProvider`, all with a minimal of code.

This includes the following:

* [Shared Elements](#Shared-Elements)
* [Enumerations](#Enumerations)
* [Protocols](#Protocols)
* [ADSQLiteProvider](#ADSQLiteProvider)
* [ADiCloudProvider](#ADiCloudProvider)
* [ADSPONProvider](#ADSPONProvider)

<a name="Shared-Elements"></a>
## Shared Elements

Contains the elements shared across all **Action Data Providers** such as `ADColumnSchema`, `ADTableSchema` and `ADCrossReference`.

<a name="Enumerations"></a>
## Enumerations

Contains the enumerations shared across all **Action Data Providers** such as `ADDataTableKeyType` and `ADDataProviderError`.

<a name="Protocols"></a>
## Protocols

Contains the protocols shared across all **Action Data Providers** such as `ADDataProvider`, `ADDataTable` and `ADDataCrossReference`.

<a name="ADSQLiteProvider"></a>
## ADSQLiteProvider

The `ADSQLiteProvider` provides both light-weight, low-level access to data stored in a SQLite database and high-level access via a **Object Relationship Management** (ORM) model. Use provided functions to read and write data stored in a `ADRecord` format from and to the database using SQL statements directly.
 
### Example:

```swift
let provider = ADSQLiteProvider.shared
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

### Remark:
The `ADSQLiteProvider` will automatically create a SQL Table from a class instance if one does not already exist. In addition, `ADSQLiteProvider` contains routines to preregister or update the schema classes conforming to the `ADDataTable` protocol which will build or modify the database tables as required.

<a name="ADiCloudProvider"></a>
## ADiCloudProvider

The `ADiCloudProvider` provides both light-weight, low-level access to data stored in a iCloud Database Container (public or private) and high-level access via a **Object Relationship Management** (ORM) model. Use provided functions to read and write data stored in a `ADRecord` format from and to the database using SQL like statements directly.
  
Optionally, pass a class instance conforming to the `ADDataTable` protocol to the `ADiCloudProvider` and it will automatically handle reading, writing and deleting data as required.
 
### Example:

```swift
let addr1 = Address(addr1: "PO Box 1234", addr2: "", city: "Houston", state: "TX", zip: "77012")
let addr2 = Address(addr1: "25 Nasa Rd 1", addr2: "Apt #123", city: "Seabrook", state: "TX", zip: "77586")
 
let p1 = Person(firstName: "John", lastName: "Doe", addresses: ["home":addr1, "work":addr2])
let p2 = Person(firstName: "Sue", lastName: "Smith", addresses: ["home":addr1, "work":addr2])
 
let group = Group(name: "Employees", people: [p1, p2])
try ADiCloudProvider.shared.save(group)
```

The following would read the data back for any modified records after a given date/time from iCloud:

```swift
let timeOfLastCacheUpdate = Date()
try ADiCloudProvider.shared.loadRows(ofType: Group.self, matchingQuery: "modificationDate >= %@", sortBy: "modificationDate", withParameters: [timeOfLastCacheUpdate]) { records, error in
	// Ensure the records were loaded
    guard error == nil else {
        print("Error loading the Groups: \(String(describing: error))")
        return
    }
    
    // Was a record returned?
    if let records = records {
        DispatchQueue.main.async {
            for record in records {
            	...
            }
        }
    }
}
```

### Remark:
The `ADiCloudProvider` will automatically create any required iCloud Table Schemas from a class instance if one does not already exist. In addition, `ADiCloudProvider` contains routines to preregister or update the schema classes conforming to the `ADDataTable` protocol which will build or modify the database schemas as required.

<a name="ADSPONProvider"></a>
## ADSPONProvider

The `ADSPONProvider` provides both light-weight, low-level access to data stored in a **Swift Portable Object Notation** (SPON) database and high-level access via a **Object Relationship Management** (ORM) model. Use provided functions to read and write data stored in a `ADRecord` format from and to the database using SQL statements directly.
 
### Example:
 
```swift
let provider = ADSPONProvider.shared
let record = try provider.query("SELECT * FROM Categories WHERE id = ?", withParameters: [1])
print(record["name"])
```
 
 Optionally, pass a class instance conforming to the `ADDataTable` protocol to the `ADSPONProvider` and it will automatically handle reading, writing and deleting data as required.
 
### Example:
 
```swift
let addr1 = Address(addr1: "PO Box 1234", addr2: "", city: "Houston", state: "TX", zip: "77012")
let addr2 = Address(addr1: "25 Nasa Rd 1", addr2: "Apt #123", city: "Seabrook", state: "TX", zip: "77586")
 
let p1 = Person(firstName: "John", lastName: "Doe", addresses: ["home":addr1, "work":addr2])
let p2 = Person(firstName: "Sue", lastName: "Smith", addresses: ["home":addr1, "work":addr2])
 
let group = Group(name: "Employees", people: [p1, p2])
try provider.save(group)
```
 
### Remark: 

The `ADSPONProvider` will automatically create a SQL Table from a class instance if one does not already exist. In addition, `ADSPONProvider` contains routines to preregister or update the schema classes conforming to the `ADDataTable` protocol which will build or modify the database tables as required.

