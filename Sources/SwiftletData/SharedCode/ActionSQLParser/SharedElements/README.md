#  Shared Elements

Contains elements shared across all **SQL Parser** DOM items such as `ADSQLColumnConstraint` and `ADSQLOrderByClause`.

This includes the following:

* [ADSQLParseQueue](#ADSQLParseQueue)
* [ADSQLColumnDefinition](#ADSQLColumnDefinition)
* [ADSQLColumnConstraint](#ADSQLColumnConstraint)
* [ADSQLTableConstraint](#ADSQLTableConstraint)
* [ADSQLResultColumn](#ADSQLResultColumn)
* [ADSQLJoinClause](#ADSQLJoinClause)
* [ADSQLOrderByClause](#ADSQLOrderByClause)
* [ADSQLSetClause](#ADSQLSetClause)

<a name="ADSQLParseQueue"></a>
## ADSQLParseQueue

Parses the raw SQL command text into a queue of decomposed substrings based on defined set of SQL language rules. A `ADSQLParseQueue` is called as the first stage of parsing a given set of one or more SQL commands. 

The `ADSQLParseQueue` provides the following:

* **shared** - A shared instance of the `ADSQLParseQueue` that can be called across object instances.
* **queue** - The queue of parsed substrings.
* **count** - The number of substrings in the queue.
* **push** - Pushes a new substring onto the queue.
* **replaceLastElement** - Replaces the last substring pushed into the queue with the given substring.
* **removeLastElement** - Removes the last substring pushed into the queue.
* **pop** - Removes the first substring from the queue.
* **lookAhead** - Returns the first substring from the queue without removing it.
* **parse** - Takes a string containing valid SQL commands and converts it into a queue of decomposed substrings based on defined set of SQL language rules.

<a name="ADSQLColumnDefinition"></a>
## ADSQLColumnDefinition

Holds information about a column definition read from a **CREATE TABLE** instruction when parsing a SQL statement.

<a name="ADSQLColumnConstraint"></a>
## ADSQLColumnConstraint

Holds information about a constraint applied to a Column Definition that has been parsed from a SQL **CREATE TABLE** instruction.

<a name="ADSQLTableConstraint"></a>
## ADSQLTableConstraint

Holds information about a constraint being applied to table from a **CREATE TABLE** SQL instruction.

<a name="ADSQLResultColumn"></a>
## ADSQLResultColumn

Holds a result column definition for a **SELECT** SQL statement.

<a name="ADSQLJoinClause"></a>
## ADSQLJoinClause

Holds the source table or table group for a SQL **SELECT** statement's **FROM** clause. If the `type` is `none` this is a single table name and not a join between two (or more) tables.

<a name="ADSQLOrderByClause"></a>
## ADSQLOrderByClause

Holds information about a result ordering statement from a SQL **SELECT** statement.

<a name="ADSQLSetClause"></a>
## ADSQLSetClause

Holds information about a value that is being written into a table's column from a SQL **UPDATE** statement.