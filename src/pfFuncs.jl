# portfolio moments

"""
    pfVariance(covs::Array{Float64, 2}, wgts::Array{Float64, 1})

Compute the portfolio variance without any re-scaling or annualization.
"""
function pfVariance(covs::Array{Float64, 2}, wgts::Array{Float64, 1})
    wgts'*covs*wgts
end

"""
    pfMu(mus::Array{Float64, 1}, wgts::Array{Float64, 1})

Compute the portfolio expectation without any re-scaling or annualization.
"""
function pfMu(mus::Array{Float64, 1}, wgts::Array{Float64, 1})
    wgts'mus
end


"""
    pfMoments(mus::Array{Float64, 1}, covs::Array{Float64, 2}, wgts::Array{Float64, 1}, riskType::String)

Compute portfolio expectation and variance or standard deviation
without any re-scaling or annualization. Allowed risk type keywords are
`std` and `var`.

## Single universe, single weights

```julia
pfMoments(mus::Array{Float64, 1}, covs::Array{Float64, 2}, wgts::Array{Float64, 1}, riskType::String)
pfMoments(mus::Array{Float64, 1}, covs::Array{Float64, 2}, pf::PF, riskType::String)
pfMoments(thisUniv::Univ, wgts::Array{Float64, 1}, riskType::String)
pfMoments(thisUniv::Univ, pf::PF, riskType::String)
```

## Multiple universes, single weights

```julia
pfMoments(univHist::UnivEvol, wgts::Array{Float64, 1}, riskType::String)
```

## Single universe, multiple weights

```julia
pfMoments(univHist::Univ, pfWgts::Array{Array{Float64, 1}, 1}, riskType::String)
pfMoments(univHist::Univ, wgts::Array{Float64, 2}, riskType::String)
```

## Multiple universes, multiple weights

```julia
pfMoments(univHist::UnivEvol, wgts::Array{Float64, 2}, riskType::String)
```

"""
function pfMoments(mus::Array{Float64, 1}, covs::Array{Float64, 2}, wgts::Array{Float64, 1}, riskType::String)
    riskOut = pfVariance(covs, wgts)
    if riskType == "std"
        riskOut = sqrt(riskOut)
    end
    pfMu(mus, wgts), riskOut
end



"""
    pfMoments(mus::Array{Float64, 1}, covs::Array{Float64, 2}, pf::PF, riskType::String)

"""
function pfMoments(mus::Array{Float64, 1}, covs::Array{Float64, 2}, pf::PF, riskType::String)
    pfMoments(mus, covs, pf.Wgts, riskType)
end


"""
    pfMoments(thisUniv::Univ, wgts::Array{Float64, 1}, riskType::String)

Applies to moments given as Univ type.
"""
function pfMoments(thisUniv::Univ, wgts::Array{Float64, 1}, riskType::String)
    pfMoments(thisUniv.mus, thisUniv.covs, wgts, riskType)
end

"""
    pfMoments(thisUniv::Univ, pf::PF, riskType::String)

"""
function pfMoments(thisUniv::Univ, pf::PF, riskType::String)
    pfMoments(thisUniv, pf.Wgts, riskType)
end

"""
    pfMoments(univHist::UnivEvol, wgts::Array{Float64, 1}, riskType::String)

Applies to multiple universes that are given as UnivEvol.
"""
function pfMoments(univHist::UnivEvol, wgts::Array{Float64, 1}, riskType::String)
    # preallocation
    nObs, nAss = size(univHist)
    allMoments = zeros(nObs, 2)

    for ii=1:nObs
        thisMu, thisRisk = pfMoments(univHist.universes[ii], wgts, riskType)
        allMoments[ii, :] = [thisMu thisRisk]
    end
    mus = allMoments[:, 1]
    risks = allMoments[:, 2]
    return mus, risks
end

"""
    pfMoments(univHist::UnivEvol, pf::PF, riskType::String)

"""
function pfMoments(univHist::UnivEvol, pf::PF, riskType::String)
    pfMoments(univHist, pf.Wgts, riskType)
end

"""
    pfMoments(univHist::Univ, pfWgts::Array{PF, 1}, riskType::String)

Applies to single universe given as type Univ and a series
of portfolio weights.
"""
function pfMoments(univHist::Univ, pfWgts::Array{PF, 1}, riskType::String)
    # get dimensions
    nObs = length(pfWgts)

    pfMus, pfRisks = (zeros(Float64, nObs), zeros(Float64, nObs))

    for ii=1:nObs
        pfMus[ii], pfRisks[ii] = pfMoments(univHist, pfWgts[ii], riskType)
    end
    return pfMus, pfRisks
end

"""
    pfMoments(univHist::UnivEvol, wgts::Array{Float64, 2}, riskType::String)

Applies to single universe and multiple portfolio weights.
"""
function pfMoments(univHist::Univ, wgts::Array{Float64, 2}, riskType::String)
    # get dimensions
    nObs, nAss = size(wgts)

    pfMus, pfRisks = (zeros(Float64, nObs), zeros(Float64, nObs))

    for ii=1:nObs
        pfMus[ii], pfRisks[ii] = pfMoments(univHist, wgts[ii, :][:], riskType)
    end
    return pfMus, pfRisks
end

"""
    pfMoments(univHist::UnivEvol, wgts::Array{Float64, 2}, riskType::String)

Applies to multiple universes and multiple portfolio weights.
"""
function pfMoments(univHist::UnivEvol, wgts::Array{Float64, 2}, riskType::String)

    # get dimensions
    nObs = size(univHist, 1)
    nObs2 = size(wgts, 1)

    if nObs != nObs2
        error("Number of different days must match")
    end

    dailyPfMus = zeros(Float64, nObs)
    dailyPfRisks = zeros(Float64, nObs)
    for ii=1:nObs
        thisUniv = univHistory.universes[ii]

        thisWgts = wgts[ii, :]
        mu, pfrisk = pfMoments(thisUniv, thisWgts[:], riskType)

        dailyPfMus[ii] = mu
        dailyPfRisks[ii] = pfrisks
    end
    return dailyPfMus, dailyPfRisks

end

"""
    pfDivers(wgts::Array{Float64, 1})

Compute portfolio diversification as

```math
\\mathcal{D}=1 - \\sqrt{\\sum_{i=1}^{d}\\left|w_{i} - \\frac{1}{d}\\right|^2}
```

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
    pfDivers(pf::PF)

"""
function pfDivers(pf::PF)
    return pfDivers(pf.Wgts)
end

"""
    pfDivers(pf::Array{PF, 1})

"""
function pfDivers(pf::Array{PF, 1})
    nPfs = length(pf)
    divVals = zeros(Float64, nPfs)
    for ii=1:nPfs
        divVals[ii] = pfDivers(pf[ii])
    end
    return divVals
end

"""
    pfDivers(pf::Array{PF, 2})

"""
function pfDivers(pf::Array{PF, 2})
    nrows, ncols = size(pf)

    divVals = zeros(Float64, nrows, ncols)
    for ii=1:nrows
        for jj=1:ncols
            divVals[ii, jj] = pfDivers(pf[ii, jj])
        end
    end
    return divVals
end

"""
    pfDivers(invests::Invest)

"""
function pfDivers(invests::Invest)
    return pfDivers(invests.pfs)
end



"""
    pfDivers(allWgts::Array{Float64, 2})

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
