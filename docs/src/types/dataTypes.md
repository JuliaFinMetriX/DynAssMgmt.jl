Return data should always come with additional meta-data to explicitly
determine return properties. Therefore, the following data types
exist. 

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

## Price and return data handling

```@docs
normalizePrices
computeReturns
aggregateReturns
rets2prices
```

## Data imputation

```@docs
DynAssMgmt.locf!
DynAssMgmt.locf
DynAssMgmt.nocb!
DynAssMgmt.nocb
```
