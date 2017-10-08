Return data always needs to be associated with meta-data:

- frequency
- discrete or logarithmic
- percentage or not

```@repl returnTypeFieldNames
using DynAssMgmt
fieldnames(ReturnType)
fieldnames(Returns)
```

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

