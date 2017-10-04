# DynAssMgmt.jl Documentation

This package implements a framework to set up and test dynamic asset
management strategies.

```@contents
```

## Portfolio functions

```@docs
pfMoments(mus::Array{Float64, 1}, covs::Array{Float64, 2}, wgts::Array{Float64, 1}, riskType::String)
pfDivers
```

## Single period strategies

```@docs
apply(thisTarget::SinglePeriodTarget, univHistory::UnivEvol)
```

```@docs
GMVP
```

```@docs
TargetVola
```

```@docs
RelativeTargetVola
```

```@docs
MaxSharpe
```

```@docs
TargetMu
```

```@docs
EffFront
```

```@docs
DivFrontSigmaTarget
```

```@docs
DivFront
```

## Internal

```@docs
DynAssMgmt.pfVariance
DynAssMgmt.pfMu(mus::Array{Float64, 1}, wgts::Array{Float64, 1})
```

```@docs
DynAssMgmt.gmvp(thisUniv::Univ)
```

```@docs
DynAssMgmt.gmvp_lev(thisUniv::Univ)
```

## Utilities

```@docs
DynAssMgmt.loadTestData(dataName::String)
```

```@docs
DynAssMgmt.locf!
DynAssMgmt.locf
DynAssMgmt.nocb!
DynAssMgmt.nocb
normalizePrices
```


## Index

```@index
```
