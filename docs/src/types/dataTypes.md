Return data always needs to be associated with meta-data:

- frequency
- discrete or logarithmic
- percentage or not


```@repl TestArray
fieldnames(Date)
```

```@example 1
fieldnames(ReturnType)
```

```@example 2
fieldnames(DynAssMgmt.ReturnType)
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

