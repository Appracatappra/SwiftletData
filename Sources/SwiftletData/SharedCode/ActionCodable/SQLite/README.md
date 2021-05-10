# SQLite

Contains the custom encoder and decoder to preprocess and post process data object models that will be sent to or returned from a `ADSQLiteProvider` and store or returned from a backing SQLite database.


## Encodable

Contains all of the routines needed to preprocess data that will be sent to a `ADSQLiteProvider`.

A `ADSQLEncoder` can return a `ADRecord`, `ADInstanceArray` or `ADInstanceDictionary` representing a given data object model or collection of object models.

## Decodable

Contains all of the routines needed to post process data returned from a `ADSQLiteProvider` and convert it back to Swift objects.


A `ADSQLDecoder` takes a `ADRecord`, `ADInstanceArray` or `ADInstanceDictionary` returned from a data source and converts it into a data object model or a collection of object models representing the given information.