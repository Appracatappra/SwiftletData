# SQLParser

The `ADSQLParser` provides the ability to parse text containing one or more SQL commands into an Action Data SQL Document Object Model (DOM) and is used to provide SQL support for data sources that don't support SQL natively (such as CloudKit and JSON).

The `ADSQLParser` uses SQLite's SQL syntax and currently support a subset of the full SQL language. For example:

```swift
let sql = """
CREATE TABLE IF NOT EXISTS parts
(
    part_id           INTEGER   PRIMARY KEY,
    stock             INTEGER   DEFAULT 0   NOT NULL,
    description       TEXT      CHECK( description != '' )    -- empty strings not allowed
);
"""
    
let instructions = try ADSQLParser.parse(sql)
print(instructions)
```

`ADSQLParser` is composed of the following pieces:

* [Shared Elements](#Shared-Elements)
* [Instructions](#Instructions)
* [Expressions](#Expressions)
* [Protocols](#Protocols)
* [Enumerations](#Enumerations)
* [ADSQLParser](#ADSQLParser)

<a name="Shared-Elements"></a>
## Shared Elements

Contains elements shared across all **SQL Parser** DOM items such as `ADSQLColumnConstraint` and `ADSQLOrderByClause`.

<a name="Instructions"></a>
## Instructions

Contains the **Object Models** used to hold the individual SQL commands parsed from the original text stream using a `ADSQLParser` such as `ADSQLCreateTableInstruction` and `ADSQLSelectInstruction`.

<a name="Expressions"></a>
## Expressions

Contains the **Object Models** used to hold the individual expressions parsed from a SQL command by a `ADSQLParser`. Expressions represent items such as the result columns for SQL **SELECT** commands, the comparisons in a **WHERE** clause or elements from a **ORDER BY** clause.

<a name="Protocols"></a>
## Protocols

Contains the protocols used to pass Instructions and Expressions throughout the **SQL Parser** system.

<a name="Enumerations"></a>
## Enumerations

Contains the Enumerations used throughout the **SQL Parser** system to define things such as SQL Keywords, Function Names, Column Data Types and Parser Error Codes.

<a name="ADSQLParser"></a>
## ADSQLParser

Parses a SQL statement into an Action Data SQL Document Object Model (DOM). This parser currently supports a subset of SQL commands as defined by SQLite.

The static `Parse` method of the `ADSQLParser` is called to convert a string containing one or more valid SQL commands into a `ADSQLInstruction` array. Each `ADSQLInstruction` instance in the array represents an instruction parsed from the source text. For example:

```swift
let sql = "SELECT * FROM parts WHERE part_id = 10" 

let instructions = try ADSQLParser.parse(sql)
print(instructions)
```

If the `ADSQLParser` is unable to parse the given source text, it will throw a `ADSQLParseError` with the details of the issue encountered.