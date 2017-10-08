Asset moments can be estimated according to a couple of ways.

## Abstract types

```@docs
DynAssMgmt.UnivEstimator
```

## Estimators

```@docs
DynAssMgmt.EWMA
```

```@repl estimatorTypeFieldNames
using DynAssMgmt
fieldnames(EWMA)
```


```@docs
getEwmaMean
getEwmaStd
getEwmaCov
```
