Asset moments are concisely stored in special types.


## Composite types

```@docs
Univ
```

```@docs
UnivEvol
```

### Fields of composite types

```@repl universeTypeFieldNames
using DynAssMgmt
fieldnames(Univ)
fieldnames(UnivEvol)
```

## Functions

```@docs
getInPercentages
annualizeRiskReturn
DynAssMgmt.getMuInPercentages
DynAssMgmt.getStdInPercentages
DynAssMgmt.getUnivExtrema
DynAssMgmt.getUnivEvolFromMatlabFormat
```
