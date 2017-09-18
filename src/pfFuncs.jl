# portfolio moments

"""
```julia
pfVariance(covs::Array{Float64, 2}, wgts::Array{Float64, 1})
```    

Compute the portfolio variance without any re-scaling or annualization.
""" 
function pfVariance(covs::Array{Float64, 2}, wgts::Array{Float64, 1})
    wgts'*covs*wgts
end

"""
```julia
pfMu(mus::Array{Float64, 1}, wgts::Array{Float64, 1})
```

Compute the portfolio expectation without any re-scaling or annualization.
"""
function pfMu(mus::Array{Float64, 1}, wgts::Array{Float64, 1})
    wgts'mus
end


"""
```julia
pfMoments(mus::Array{Float64, 1}, covs::Array{Float64, 2}, wgts::Array{Float64, 1})
```

Compute portfolio variance and expectation without any re-scaling or
annualization.

## Single universe, single weights

```julia
pfMoments(mus::Array{Float64, 1}, covs::Array{Float64, 2}, wgts::Array{Float64, 1})
pfMoments(thisUniv::Univ, wgts::Array{Float64, 1})
```

## Multiple universes, single weights

```julia
pfMoments(univHist::UnivEvol, wgts::Array{Float64, 1})
```

## Single universe, multiple weights

```julia
pfMoments(univHist::Univ, pfWgts::Array{Array{Float64, 1}, 1})
pfMoments(univHist::Univ, wgts::Array{Float64, 2})
```

## Multiple universes, multiple weights

```julia
pfMoments(univHist::UnivEvol, wgts::Array{Float64, 2})
```

"""
function pfMoments(mus::Array{Float64, 1}, covs::Array{Float64, 2}, wgts::Array{Float64, 1})
    pfMu(mus, wgts), pfVariance(covs, wgts)
end

"""
    pfMoments(thisUniv::Univ, wgts::Array{Float64, 1})

Applies to moments given as Univ type.
"""
function pfMoments(thisUniv::Univ, wgts::Array{Float64, 1})
    pfMoments(thisUniv.mus, thisUniv.covs, wgts)
end

"""
    pfMoments(univHist::UnivEvol, wgts::Array{Float64, 1})

Applies to multiple universes that are given as UnivEvol.
"""
function pfMoments(univHist::UnivEvol, wgts::Array{Float64, 1})
    # preallocation
    nObs, nAss = size(univHist)
    allMoments = zeros(nObs, 2)

    for ii=1:nObs
        thisMu, thisVariance = pfMoments(univHist.universes[ii], wgts)
        allMoments[ii, :] = [thisMu thisVariance]
    end
    mus = allMoments[:, 1]
    vars = allMoments[:, 2]
    return mus, vars
end

"""
    pfMoments(univHist::Univ, pfWgts::Array{Array{Float64, 1}, 1})

Applies to single universe given as type Univ and a series
of portfolio weights.
"""
function pfMoments(univHist::Univ, pfWgts::Array{Array{Float64, 1}, 1})
    # get dimensions
    nObs = size(pfWgts, 1)

    pfMus, pfVars = (zeros(Float64, nObs), zeros(Float64, nObs))

    for ii=1:nObs
        pfMus[ii], pfVars[ii] = pfMoments(univHist, pfWgts[ii][:])
    end
    return pfMus, pfVars
end

"""
    pfMoments(univHist::UnivEvol, wgts::Array{Float64, 2})

Applies to single universe and multiple portfolio weights.
"""
function pfMoments(univHist::Univ, wgts::Array{Float64, 2})
    # get dimensions
    nObs, nAss = size(wgts)

    pfMus, pfVars = (zeros(Float64, nObs), zeros(Float64, nObs))

    for ii=1:nObs
        pfMus[ii], pfVars[ii] = pfMoments(univHist, wgts[ii, :][:])
    end
    return pfMus, pfVars
end

"""
    pfMoments(univHist::UnivEvol, wgts::Array{Float64, 2})

Applies to multiple universes and multiple portfolio weights.
"""
function pfMoments(univHist::UnivEvol, wgts::Array{Float64, 2})

    # get dimensions
    nObs = size(univHist, 1)
    nObs2 = size(wgts, 1)

    if nObs != nObs2
        error("Number of different days must match")
    end

    dailyPfMus = zeros(Float64, nObs)
    dailyPfVars = zeros(Float64, nObs)
    for ii=1:nObs
        thisUniv = univHistory.universes[ii]

        thisWgts = wgts[ii, :]
        mu, pfvar = pfMoments(thisUniv, thisWgts[:])

        dailyPfMus[ii] = mu
        dailyPfVars[ii] = pfvar
    end
    return dailyPfMus, dailyPfVars

end

"""
```julia
pfDivers(wgts::Array{Float64, 1})
```

Compute portfolio diversification as

``\mathcal{D}=\sqrt{\sum_{i=1}^{d}|w_{i} - frac{1}{d}|^2}``
"""
function pfDivers(wgts::Array{Float64, 1})
    # get number of assets
    nAss = size(wgts, 1)

    # get equal weights
    eqWgts = ones(Float64, nAss) ./ nAss

    # compute diversification
    1 - norm(wgts .- eqWgts)
end


"""
```julia
pfDivers(allWgts::Array{Float64, 2})
```

Applies to series of portfolio weights, with individual weights
given in rows.
"""
function pfDivers(allWgts::Array{Float64, 2})
    # get number of assets
    nPfs, nAss = size(allWgts)

    # get equal weights
    eqWgts = ones(Float64, nAss) ./ nAss

    # compute diversification
    allDivs = zeros(Float64, nPfs)
    for ii=1:nPfs
        allDivs[ii] = pfDivers(allWgts[ii, :][:])
    end
    return allDivs

end
