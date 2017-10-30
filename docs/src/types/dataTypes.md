Return data should always come with additional meta-data to explicitly
determine return properties. Therefore, the following data types
exist. 

## Composite types

```@docs
ReturnType
Returns
Prices
Performances
```
### Fields of composite types

```@repl returnTypeFieldNames
using DynAssMgmt
fieldnames(ReturnType)
fieldnames(Returns)
fieldnames(Prices)
fieldnames(Performances)
```

## Price and return data handling

For each data type, there exist several different scales in which the
data could be given. For example, prices can be regular discrete
prices, or logarithmic prices. Similarly, performances can be measured
in percentages and discrete or logarithmic. For each data type,
however, there exists a default scale in which any given instance can
be translated using function `standardize`. 

```@docs
standardize
```

Defining conversion methods from any possible data scale to this
default scale will allow conversion between any arbitrary scales. For
example, for `Prices` the following methods exist:

```@docs
getLogPrices
getDiscretePrices
normalizePrices
```

As `Returns`, `Prices` and `Performances` are closely interconnected,
there also exist default conversion methods between them. These
methods make use of the following low-level functions:

```@docs
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
