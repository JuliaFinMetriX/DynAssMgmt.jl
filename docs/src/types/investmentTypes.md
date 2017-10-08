Multiple optimal portfolios exist in cross-section as well as over
time. 

```@docs
PF
Invest
```

```@repl investTypeFieldNames
using DynAssMgmt
fieldnames(PF)
fieldnames(Invest)
```


## Portfolio functions

```@docs
pfMoments(mus::Array{Float64, 1}, covs::Array{Float64, 2}, wgts::Array{Float64, 1}, riskType::String)
pfDivers
```

## Internal

```@docs
DynAssMgmt.pfVariance
DynAssMgmt.pfMu(mus::Array{Float64, 1}, wgts::Array{Float64, 1})
```
