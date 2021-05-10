#  Expressions

Contains the **Object Models** used to hold the individual expressions parsed from a SQL command by a `ADSQLParser`. Expressions represent items such as the result columns for SQL **SELECT** commands, the comparisons in a **WHERE** clause or elements from a **ORDER BY** clause.

This includes the following:

* [ADSQLLiteralExpression](#ADSQLLiteralExpression)
* [ADSQLUnaryExpression](#ADSQLUnaryExpression)
* [ADSQLBinaryExpression](#ADSQLBinaryExpression)
* [ADSQLFunctionExpression](#ADSQLFunctionExpression)
* [ADSQLBetweenExpression](#ADSQLBetweenExpression)
* [ADSQLInExpression](#ADSQLInExpression)
* [ADSQLWhenExpression](#ADSQLWhenExpression)
* [ADSQLCaseExpression](#ADSQLCaseExpression)
* [ADSQLForeignKeyExpression](#ADSQLForeignKeyExpression)

<a name="ADSQLLiteralExpression"></a>
## ADSQLLiteralExpression

Defines a literal expression used in a SQL instruction such as a column name, integer value or string constant value.

<a name="ADSQLUnaryExpression"></a>
## ADSQLUnaryExpression

Defines a unary expression used in a SQL instruction such as forcing a value to be positive or negative.

<a name="ADSQLBinaryExpression"></a>
## ADSQLBinaryExpression

Defines a binary operation being performed on two expressions in a SQL instruction such as adding two values or comparing two values to see if they are equal.

<a name="ADSQLFunctionExpression"></a>
## ADSQLFunctionExpression

Defines a function being called in a SQL instruction such as `count` or `sum`.

<a name="ADSQLBetweenExpression"></a>
## ADSQLBetweenExpression

Defines a between expression used in a SQL instruction to test if a value is between two other values.

<a name="ADSQLInExpression"></a>
## ADSQLInExpression

Defines a in expression used in a SQL instruction to see if a value is in the list of give values.

<a name="ADSQLWhenExpression"></a>
## ADSQLWhenExpression

Defines a when clause using in a **CASE** clause in a SQL instruction.

<a name="ADSQLCaseExpression"></a>
## ADSQLCaseExpression

Defines a case clause used in a SQL instruction.

<a name="ADSQLForeignKeyExpression"></a>
## ADSQLForeignKeyExpression

Defines a foreign key expression used in a SQL statement.