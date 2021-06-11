#  Enumerations

Contains the Enumerations used throughout the **SQL Parser** system to define things such as SQL Keywords, Function Names, Column Data Types and Parser Error Codes.

This includes the following:

* [ADSQLKeyword](#ADSQLKeyword)
* [ADSQLFunction](#ADSQLFunction)
* [ADSQLColumnType](#ADSQLColumnType)
* [ADSQLParseError](#ADSQLParseError)
* [ADSQLConflictHandling](#ADSQLConflictHandling)

<a name="ADSQLKeyword"></a>
## ADSQLKeyword

Contains a list of all valid SQL keywords that the `ADSQLParser` can understand.

The `get` static method attempts to convert the given string value into a `SQLKeyword` and ignores case. For example:

```swift
let key = ADSQLKeyword.get("select")
```

<a name="ADSQLFunction"></a>
## ADSQLFunction

Defines the type of functions that can be called in a SQL expression.

The `get` static method attempts to convert the given string value into a `ADSQLFunction` and ignores case. For example:

```swift
let key = ADSQLFunction.get("count")
```

<a name="ADSQLColumnType"></a>
## ADSQLColumnType

Defines the type of a column stored in a SQL data source.

The `get` static method attempts to convert the given string value into a `ADSQLColumnType` and ignores case. For example:

```swift
let key = ADSQLColumnType.get("integer")
```

The `set` method attempts to set the column type from a string value and ignores case. For example:

```swift
let type = ADSQLColumnType.noneType
type.set("text")
```

<a name="ADSQLParseError"></a>
## ADSQLParseError

Defines the type of errors that can arise when parsing a SQL command string. The `message` property contains the details of the given failure.

<a name="ADSQLConflictHandling"></a>
## ADSQLConflictHandling

Defines the type of conflict handling that can be applied to a column or table constraint.