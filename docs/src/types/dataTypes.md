Return data always needs to be associated with meta-data:

- frequency
- discrete or logarithmic
- percentage or not

```@repl fieldNams
fieldnames(DynAssMgmt.ReturnType)
```

```@repl TestArray
fieldnames(Date)
```

```@example 1
fieldnames(ReturnType)
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

