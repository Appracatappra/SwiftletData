#  Instructions

Contains the **Object Models** used to hold the individual SQL commands parsed from the original text stream using a `ADSQLParser` such as `ADSQLCreateTableInstruction` and `ADSQLSelectInstruction`.

This includes the following:

* [ADSQLAlterTableInstruction](#ADSQLAlterTableInstruction)
* [ADSQLCreateIndexInstruction](#ADSQLCreateIndexInstruction)
* [ADSQLCreateTableInstruction](#ADSQLCreateTableInstruction)
* [ADSQLCreateTriggerInstruction](#ADSQLCreateTriggerInstruction)
* [ADSQLCreateViewInstruction](#ADSQLCreateViewInstruction)
* [ADSQLSelectInstruction](#ADSQLSelectInstruction)
* [ADSQLInsertInstruction](#ADSQLInsertInstruction)
* [ADSQLUpdateInstruction](#ADSQLUpdateInstruction)
* [ADSQLDeleteInstruction](#ADSQLDeleteInstruction)
* [ADSQLDropInstruction](#ADSQLDropInstruction)
* [ADSQLTransactionInstruction](#ADSQLTransactionInstruction)

<a name="ADSQLAlterTableInstruction"></a>
## ADSQLAlterTableInstruction

Holds the information for a SQL **ALTER TABLE** instruction.

<a name="ADSQLCreateIndexInstruction"></a>
## ADSQLCreateIndexInstruction

Holds the information for a SQL **CREATE INDEX** instruction.

<a name="ADSQLCreateTableInstruction"></a>
## ADSQLCreateTableInstruction

Holds information about a SQL **CREATE TABLE** instruction.

<a name="ADSQLCreateTriggerInstruction"></a>
## ADSQLCreateTriggerInstruction

Holds information about a SQL **CREATE TRIGGER** instruction.

<a name="ADSQLCreateViewInstruction"></a>
## ADSQLCreateViewInstruction

Holds all the information for a SQL **CREATE VIEW** instruction.

<a name="ADSQLSelectInstruction"></a>
## ADSQLSelectInstruction

Holds all information about a SQL **SELECT** instruction.

<a name="ADSQLInsertInstruction"></a>
## ADSQLInsertInstruction

Holds all information about a SQL **INSERT** instruction.

<a name="ADSQLUpdateInstruction"></a>
## ADSQLUpdateInstruction

Holds all of the information for a SQL **UPDATE** instruction.

<a name="ADSQLDeleteInstruction"></a>
## ADSQLDeleteInstruction

Holds all information about a SQL **DELETE** instruction.

<a name="ADSQLDropInstruction"></a>
## ADSQLDropInstruction

Holds all information about a SQL **DROP** instruction.

<a name="ADSQLTransactionInstruction"></a>
## ADSQLTransactionInstruction

Holds all information about a SQL **BEGIN**, **COMMIT**, **END**, **ROLLBACK**, **SAVEPOINT** or **RELEASE** instruction.

