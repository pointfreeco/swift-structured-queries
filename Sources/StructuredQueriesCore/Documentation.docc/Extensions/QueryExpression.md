# ``StructuredQueriesCore/QueryExpression``

## Topics

### Operators

- ``==(_:_:)``
- ``!=(_:_:)``
- ``!(_:)``

### Scalar functions

- ``length()``
- ``octetLength()``
- ````

### Aggregate functions

- ``count(distinct:filter:)``
- ``count(filter:)``
- ``avg(distinct:filter:)``
- ``sum(distinct:filter:)``
- ``total(distinct:filter:)``
- ``groupConcat(_:order:filter:)``
- ``groupConcat(distinct:order:filter:)``

### JSON functions

- ``jsonArrayLength()``
- ``jsonGroupArray(order:filter:)``

### Optionality

- ``map(_:)``
- ``flatMap(_:)``
