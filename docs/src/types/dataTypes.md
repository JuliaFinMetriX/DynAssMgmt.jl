Return data always needs to be associated with meta-data:

- frequency
- discrete or logarithmic
- percentage or not


```@example TestArray
fieldnames(Date)
```

```@example ReturnType
fieldnames(ReturnType)
```

```@example ReturnType2
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

