# Enumerations

Contains the enumerations shared across all **Action Data Providers** such as `ADDataTableKeyType` and `ADDataProviderError`.

This includes the following:

* [ADDataTableKeyType](#ADDataTableKeyType)
* [ADDataProviderError](#ADDataProviderError)
* [ADSQLExecutionError](#ADSQLExecutionError)

<a name="ADDataTableKeyType"></a>
## ADDataTableKeyType

Defines the type of primary key that has been specified for a class conforming to the `ADDataTable` protocol as one of the following:

* **uniqueValue** - Specifies that the given primary key must be unique and not already exist for any other key in the data provider's data source.
* **autoIncrementingInt** - For an `Int` type of primary key, automatically assign a key value when a new row is added to the data provider's data source. 
	
	> ℹ️ **NOTE:** For SQL based data providers, the ID is typically generated using the `AUTOINCREMENT` key type.
* **computedInt** - For an `Int` type of primary key, automatically assign a key value when a new row is added to the data provider's data source by finding the largest used ID number and adding one to it. 
	
	> ℹ️ **NOTE:** This key type is provided as a workaround to issues with the SQLite database's `AUTOINCREMENT` implementation and to provide a valid ID to a record when it is first created (instead of after its been saved) for parent-child table relationships.
* **autoUUIDString** - For a `String` type of primary key, automatically assign a **UUID** as the key value when a new class conforming to the `ADDataTable` protocol is created.

<a name="ADDataProviderError"></a>
## ADDataProviderError

Defines the type of errors that can arise when working with a data provider that conforms to the `ADDataProvider` protocol as one of the following:

* **dataSourceNotOpen** - The data provider is attempting to work with a datasource before it has been opened.
* **dataSourceCopyFailed** - Failed to copy a writable version of the database source from the app's bundle to the documents directory.
* **dataSourceNotFound** - Unable to open the data source from the given location or with the given name.
* **unableToOpenDataSource** - The data provider was unable to open the given data source.
* **failedToDeleteSource** - The data provider failed to delete the data source.
* **tableNotFound** - The data provider does not have the requested table name on file.
* **failedToPrepareSQL** - The data provider was unable to prepare the SQL statement for execution while binding the passed set of parameters.
* **parameterCountMismatch** - The number of parameters specified in the SQL statement did not match the number of parameters passed to the data provider.
* **unableToBindParameter** - The data provider was unable to bind a given parameter to the SQL statement.
* **failedToCreateTable** - The data provider was unable to create the requested table in the data source.
* **failedToExecuteSQL** - The data provider was unable to execute the given SQL statement.
* **failedToUpdateTableSchema** - The data provider was unable to update the given table schema to the new version.
* **unableToGetRows** - The data provider was unable to fetch the requested row(s) from the data source.
* **batchUpdateFailed** - The data provider was unable to complete the given batch update command.
* **missingRequiredValue** - While attempting to create or update a table schema, the data provider encountered a `nil` value. Use either the `register` or `update` functions with a fully populated **default value class instance** (with all values set to a default, non-nil value) to create or update the table schema.

<a name="ADSQLExecutionError"></a>
## ADSQLExecutionError

Defines the errors that can be thrown when executing SQL statements as one of the following:

* **duplicateTable** - The table already exists inside of the data store.
* **unsupportedCommand** - The requested SQL command isn't supported by Action Data or then current Data Provider.
* **invalidCommand** - The requested SQL command isn't valid in the given context.
* **unknownTable** - The data store doesn't contain the given table.
* **unknownColumn** - The data store doesn't contain the given column in the given table.
* **syntaxError** - The data store could not execute the SQL command because it contained a syntax error.
* **invalidRecord** - The `ADRecord` is not valid for the given data table.
* **duplicateRecord** - A record with the same primary key already exists in the table.
* **failedCheckConstraint** - An attempt to insert or update a record failed due to a CHECK constraint.
* **noRowsReturned** -  The SELECT clause in a CREATE statement returned no rows.
* **unevenNumberOfParameters** - The number of parameters (specified by a `?` in the SQL statement) did not match the number of parameters provided.
