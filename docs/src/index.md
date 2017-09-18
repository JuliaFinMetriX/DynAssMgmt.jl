# DynAssMgmt.jl Documentation

This package implements a framework to set up and test dynamic asset
management strategies.

```@contents
```

## Portfolio functions

```@docs
pfVariance
```

```@docs
DynAssMgmt.pfMu(mus::Array{Float64, 1}, wgts::Array{Float64, 1})
```

```@docs
pfMoments(mus::Array{Float64, 1}, covs::Array{Float64, 2}, wgts::Array{Float64, 1})
```


```@docs
DynAssMgmt.pfDivers
```

## Single period strategies

```@docs
gmvp(thisUniv)
```

```@docs
gmvp_lev(thisUniv::Univ)
```

## Index

```@index
```
