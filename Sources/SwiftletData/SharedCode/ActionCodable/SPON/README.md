# SPON

Contains the custom encoder and decoder to preprocess and post process data object models that will be sent to or returned from a `ADSPONiteProvider` and store or returned from a backing SQLite database.


## Encodable

Contains all of the routines needed to preprocess data that will be sent to a `ADSPONiteProvider`.

A `ADSPONEncoder` can return a `ADRecord`, `ADInstanceArray` or `ADInstanceDictionary` representing a given data object model or collection of object models.

## Decodable

Contains all of the routines needed to post process data returned from a `ADSPONiteProvider` and convert it back to Swift objects.


A `ADSPONDecoder` takes a `ADRecord`, `ADInstanceArray` or `ADInstanceDictionary` returned from a data source and converts it into a data object model or a collection of object models representing the given information.
