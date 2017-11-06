## define Portfolio API

"""
```julia
PF(wgts::Array{Float64, 1})
```

Implementation of a single portfolio. Weights have to be
positive (short-selling is not allowed) and need to add up to 1.
"""
struct PF
    Wgts::Array{Float64, 1}

    function PF(xx)
        if abs(sum(xx) - 1) > 0.001
            error("Portfolio weights must sum to 1")
        end
        if any(xx .< -0.001)
            display(xx)
            error("All portfolio weights need to be positive")
        end

        # make perfect weights
        xx[xx .< 0] = 0
        xx = xx ./ sum(xx)

        return new(xx)
    end
end

##

import Base.size
size(pf::PF) = size(pf.Wgts, 1)

import Base.convert
function convert(::Type{Array{Float64, 2}}, xx::Array{PF, 1})
    nPfs = size(xx, 1)
    nAss = size(xx[1])

    allWgts = zeros(Float64, nPfs, nAss)
    for ii=1:nPfs
        allWgts[ii, :] = xx[ii].Wgts'
    end
    return allWgts
end

## Investments

"""
```julia
Invest(pfs::Array{PF, 2}, spectrum::Array{SinglePeriodTarget, 1}, dates::Array{Date, 1}, assetLabels::Array{String, 1}, stratLabels::Array{String, 1})
```

Implementation of investments as collection of portfolios. Portfolios
are equipped with additional descriptive meta-data: which strategies were used,
which universe and which time period.
"""
struct Invest
    pfs::Array{PF, 2}
    strategies::Array{SinglePeriodTarget, 1}
    dates::Array{Date, 1}
    assetLabels::Array{String, 1}
    stratLabels::Array{String, 1}
end

function Invest(pfs::Array{PF, 2}, spectrum::SinglePeriodSpectrum, dates::Array{Date, 1}, assetLabels::Array{String, 1}, stratLabels::Array{String, 1})
    strats = getSingleTargets(spectrum)
    return Invest(pfs, strats, dates, assetLabels, stratLabels)
end

function Invest(pfs::Array{PF, 1}, strat::SinglePeriodTarget, dates::Array{Date, 1}, assetLabels::Array{String, 1}, stratLabels::Array{String, 1})
    pfs = reshape(pfs, length(pfs), 1)
    return Invest(pfs, [strat], dates, assetLabels, stratLabels)
end


import Base.size
size(inv::Invest) = (size(inv.dates, 1), size(inv.strategies, 1), size(inv.assetLabels, 1))


## make apply generalization to UnivEvols including potential parallelization
function apply(thisTarget::SinglePeriodSpectrum, univHistory::UnivEvol, stratLabels::Array{String, 1})
    # check for multiple processes

    nProcesses = nprocs()

    if nProcesses == 1
        allPfs = [apply(thisTarget, x) for x in univHistory.universes]
        allPfs = vcat(allPfs...)

    elseif nProcesses > 1

        # distribute historic universes over processes
        DUnivs = distribute(univHistory.universes)

        allWgtsDistributed = map(x -> apply(thisTarget, x), DUnivs)
        allPfs = convert(Array, allWgtsDistributed)
        allPfs = vcat(allPfs...)

    end

    firstInv = Invest(allPfs, thisTarget, univHistory.dates, univHistory.assetLabels, stratLabels)

end

function apply(thisTarget::SinglePeriodSpectrum, univHistory::UnivEvol)
    # get default strategy labels
    stratLabels = getName(thisTarget)

    return apply(thisTarget, univHistory, stratLabels)
end

function apply(thisTarget::SinglePeriodTarget, univHistory::UnivEvol)
    # get default strategy labels
    stratLabel = getName(thisTarget)

    return apply(thisTarget, univHistory, [stratLabel])
end
