## define backtest functions

# - which strategy (problematic with iterative weight filters)
# - which universe
# - which date range

struct Bktest
    strategies
    assetLabels

end

##

function evalPerf(someInvs::Invest, rets::Returns)

    # make fractional, discrete returns
    standardizedRets = standardize(rets)
    discRets = standardizedRets.data

    # get common dates
    jointDates = intersect(someInvs.dates, discRets.timestamp)
    # TODO: use all dates where returns exist by carrying forward
    # portfolio weights

    # get dimensions
    nObs = length(jointDates)
    xx, nStrats, xx2 = size(someInvs)

    # preallocation
    perfs = zeros(Float64, nObs, nStrats)

    assLabs = someInvs.assetLabels

    # get respective returns
    xx = discRets[jointDates]
    xx = xx[assLabs...]
    perfDates = xx.timestamp
    associatedRets = xx.values

    # get respective weight rows
    xxIndsWgts = findin(jointDates, someInvs.dates)

    # adjust weights and returns for 1 period time lag
    associatedRets = associatedRets[2:end, :]
    xxIndsWgts = xxIndsWgts[1:end-1]

    # get respective weights
    for thisStratInd = 1:nStrats
        # get respective weights
        allWgts = convert(Array{Float64, 2}, someInvs.pfs[xxIndsWgts, thisStratInd])

        # calculate performances
        xxWgtRets = sum(allWgts .* associatedRets, 2)[:]
        pfVals = aggregateReturns(xxWgtRets, standardizedRets.retType, true)

        # store performances
        perfs[:, thisStratInd] = pfVals
    end

    perfsTimeArray = TimeArray(perfDates[:], perfs)
    perfs = Performances(perfsTimeArray, ReturnType())

end

"""
    evalDDowns(pfVals::Array{Float64, 1})

Compute drawdowns from discrete prices. Drawdowns are given as percentage values.
"""
function evalDDowns(pfVals::Array{Float64, 1})
    cumMaxPrices = accumulate(max, pfVals, 1)
    ddowns = 100*(pfVals ./ cumMaxPrices - 1)
end

"""
    evalDDowns(pfTA::TimeArray)
"""
function evalDDowns(pfTA::TimeArray)
    # get values only
    pfVals = pfTA.values

    ddownsVals = zeros(Float64, size(pfVals))
    for ii=1:size(pfVals, 2)
        ddownsVals[:, ii] = evalDDowns(pfVals[:, ii])
    end

    # build TimeArray again
    return TimeArray(pfTA.timestamp, ddownsVals, pfTA.colnames)
end

"""
    evalDDowns(prices::Prices)
"""
function evalDDowns(prices::Prices)
    stdPrices = standardize(prices)
    return evalDDowns(stdPrices.data)
end

"""
    evalDDowns(perfs::Performances)
"""
function evalDDowns(perfs::Performances)
    prices = convert(Prices, perfs)
    stdPrices = standardize(prices)
    return evalDDowns(stdPrices.data)
end

## performance statistics type

"""
    PerfStats(vals::Array{Float64, 1}, statNams::Array{Symbol, 1})

Performance statistics type, collecting risk / return metrics for single
realized portfolio price path.
"""
type PerfStats
    FullPercRet::Float64
    SpMuPerc::Float64
    SpSigmaPerc::Float64
    MuDailyToAnnualPerc::Float64
    SigmaDailyToAnnualPerc::Float64
    SpVaRPerc::Float64
    MaxDD::Float64
    VaR::Float64
    GeoMean::Float64
    # DateRange::Array{Date, 1}
end

PerfStats() = PerfStats(NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN)

"""
    PerfStats(vals::Array{Float64, 1}, statNams::Array{Symbol, 1})

Outer constructor for `PerfStats` type.
"""
function PerfStats(vals::Array{Float64, 1}, statNams::Array{Symbol, 1})
    # preallocate
    perfStatInstance = PerfStats()

    for ii=1:length(vals)
        setfield!(perfStatInstance, statNams[ii], vals[ii])
    end

    return perfStatInstance
end

## performance statistics functions

"""
    fullPercRet(pfVals::Array{Float64, 1})

Get overall performance as percentage return.
"""
fullPercRet(pfVals::Array{Float64, 1}) = 100*(pfVals[end] - pfVals[1])./pfVals[1]

"""
    spVaR(vals::Array{Float64, 1}, alpha::Float64)

Empricial VaR to confidence level `alpha`.
"""
spVaR(vals::Array{Float64, 1}, alpha::Float64) = (-1)*quantile(vals, 1-alpha)


"""
    maxDD(pfVals::Array{Float64, 1})

Get maximum drawdown from price series.
"""
maxDD(pfVals::Array{Float64, 1}) = (-1)*minimum(evalDDowns(pfVals))

"""
    evalPerfStats(singlePfVals::Array{Float64, 1})

Derive risk / return metrics for single vector of prices.
"""
function evalPerfStats(singlePfVals::Array{Float64, 1})
    # define default return type
    defReturnType = ReturnType(true, false, Dates.Day(1), false)

    # get returns
    singleDiscRets = computeReturns(singlePfVals, defReturnType)

    # compute performance statistics
    perfStats = Float64[]
    statNames = Symbol[]

    # full period percentage return
    push!(perfStats, fullPercRet(singlePfVals))
    push!(statNames, :FullPercRet)

    # single period mus
    spmuval = mean(singleDiscRets)
    push!(perfStats, spmuval)
    push!(statNames, :SpMuPerc)

    spsigmaval = std(singleDiscRets)
    push!(perfStats, spsigmaval)
    push!(statNames, :SpSigmaPerc)

    muScaled, sigmaScaled = DynAssMgmt.annualizeRiskReturn(spmuval, spsigmaval, defReturnType)
    push!(perfStats, muScaled)
    push!(perfStats, sigmaScaled)
    push!(statNames, :MuDailyToAnnualPerc)
    push!(statNames, :SigmaDailyToAnnualPerc)

    push!(perfStats, spVaR(singleDiscRets, 0.95))
    push!(statNames, :SpVaRPerc)

    push!(perfStats, maxDD(singlePfVals))
    push!(statNames, :MaxDD)

    return (perfStats, statNames)
end

"""
    evalPerfStats(prices::Prices)

Derive risk / return metrics for Prices and return as PerfStats type.
"""
function evalPerfStats(prices::Prices)
    stdPrices = standardize(prices)

    nObs, nTimeSeries = size(prices.data.values)
    allPerfStats = Array(PerfStats, 1, nTimeSeries)
    for ii=1:nTimeSeries
        xxVals, xxNams = evalPerfStats(prices.data.values[:, ii])
        thisPerfStats = DynAssMgmt.PerfStats(xxVals, xxNams)
        allPerfStats[1, ii] = thisPerfStats
    end
    return allPerfStats
end

"""
    evalPerfStats(perfs::Performances)

Derive risk / return metrics for Performances and return as PerfStats type.
"""
function evalPerfStats(perfs::Performances)
    prices = standardize(perfs)
    return evalPerfStats(prices)
end

function evalPerfStats(singlePfVals::Array{Float64, 1}, dats::Array{Date, 1})
    # TODO: make use of dates array

    # get statistics that do not require dates
    perfStats, statNames = evalPerfStats(singlePfVals)
end
