# DynAssMgmt.jl Documentation

This package implements a framework to set up and test dynamic asset
management strategies.

```@contents
```

## Portfolio functions

```@docs
DynAssMgmt.pfVariance(covs::Array{Float64, 2}, wgts::Array{Float64, 1})
```

```@docs
DynAssMgmt.pfMu(mus::Array{Float64, 1}, wgts::Array{Float64, 1})
```

```@docs
DynAssMgmt.pfMoments(mus, covs, wgts)
```

```@docs
DynAssMgmt.pfMoments(mus::Array{Float64, 1}, covs::Array{Float64, 2}, wgts::Array{Float64, 1})
DynAssMgmt.pfMoments(thisUniv::Univ, wgts::Array{Float64, 1})
DynAssMgmt.pfMoments(univHist::UnivEvol, wgts::Array{Float64, 1})
DynAssMgmt.pfMoments(univHist::Univ, pfWgts::Array{Array{Float64, 1}, 1})
DynAssMgmt.pfMoments(univHist::Univ, wgts::Array{Float64, 2})
DynAssMgmt.pfMoments(univHist::UnivEvol, wgts::Array{Float64, 2})
```

```@docs
DynAssMgmt.pfDivers(allWgts::Array{Float64, 2})
```

```@docs
DynAssMgmt.pfDivers(wgts::Array{Float64, 1})
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
