For given asset moments, there are several strategies to select an
optimal portfolio.

### Fields of composite types

```@repl strategyTypeFieldNames
using DynAssMgmt
fieldnames(GMVP)
fieldnames(TargetVola)
fieldnames(RelativeTargetVola)
fieldnames(MaxSharpe)
fieldnames(TargetMu)
fieldnames(EffFront)
fieldnames(DivFrontSigmaTarget)
fieldnames(DivFront)
```

## Single period strategies

### Usage

```@docs
apply(thisTarget::SinglePeriodTarget, univHistory::UnivEvol)
```

### Abstract types

```@docs
DynAssMgmt.SinglePeriodTarget
DynAssMgmt.SinglePeriodSpectrum
```

### Composite types

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
DynAssMgmt.gmvp(thisUniv::Univ)
```

```@docs
DynAssMgmt.gmvp_lev(thisUniv::Univ)
```
