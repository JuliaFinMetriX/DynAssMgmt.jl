Asset moments can be estimated according to a couple of ways.

## Abstract types

```@docs
DynAssMgmt.UnivEstimator
```

## Estimators

```@docs
DynAssMgmt.EWMA
```

### Fields of composite types

```@repl estimatorTypeFieldNames
using DynAssMgmt
fieldnames(EWMA)
```

## Usage

```@docs
apply(thisEstimator::UnivEstimator, rets::Returns)
applyOverTime
```

## Functions

```@docs
getEwmaMean
getEwmaStd
getEwmaCov
```
