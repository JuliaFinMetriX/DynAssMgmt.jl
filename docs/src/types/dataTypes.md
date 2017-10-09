Return data always needs to be associated with meta-data:

- frequency
- discrete or logarithmic
- percentage or not

## Composite types

```@docs
ReturnType
Returns
```
### Fields of composite types

```@repl returnTypeFieldNames
using DynAssMgmt
fieldnames(ReturnType)
fieldnames(Returns)
```

## Functions

```@docs
DynAssMgmt.locf!
DynAssMgmt.locf
DynAssMgmt.nocb!
DynAssMgmt.nocb
normalizePrices
computeReturns
aggregateReturns
rets2prices
```

