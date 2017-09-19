# DynAssMgmt.jl Documentation

This package implements a framework to set up and test dynamic asset
management strategies.

```@contents
```

## Portfolio functions

```@docs
pfMoments(mus::Array{Float64, 1}, covs::Array{Float64, 2}, wgts::Array{Float64, 1})
pfDivers
```

## Single period strategies

```@docs
DynAssMgmt.gmvp(thisUniv)
```

```@docs
DynAssMgmt.gmvp_lev(thisUniv::Univ)
```

## Internal

```@docs
DynAssMgmt.pfVariance
DynAssMgmt.pfMu(mus::Array{Float64, 1}, wgts::Array{Float64, 1})
```


## Index

```@index
```
