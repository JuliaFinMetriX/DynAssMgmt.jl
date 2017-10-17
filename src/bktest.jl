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
    standardizedRets = standardizeReturns(rets)
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

end


# ddowns
function evalDDowns(perfVals::Array{Float64, 1})
    cumMaxPrices = cummax(perfVals)
    ddowns = 100*(perfVals ./ cumMaxPrices - 1)
end

function evalDDowns(perfTA::TimeArray)
    # get values only
    perfVals = perfTA.values

    ddownsVals = zeros(Float64, size(perfVals))
    for ii=1:size(perfVals, 2)
        ddownsVals[:, ii] = evalDDowns(perfVals[:, ii])
    end

    # build TimeArray again
    return TimeArray(perfTA.timestamp, ddownsVals, perfTA.colnames)
end


## get overall performance statistics
fullPercRet(pfVals::Array{Float64, 1}) = 100*(pfVals[end] - pfVals[1])./pfVals[1]
spMu(vals::Array{Float64, 1}) = mean(vals)
spSigma(vals::Array{Float64, 1}) = std(vals)
spVaR(vals::Array{Float64, 1}, alpha::Float64) = (-1)*quantile(vals, 1-alpha)
maxDD(pfVals::Array{Float64, 1}) = (-1)*minimum(evalDDowns(pfVals))

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
    spmuval = spMu(singleDiscRets)
    push!(perfStats, spmuval)
    push!(statNames, :SpMuPerc)

    spsigmaval = spSigma(singleDiscRets)
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

function evalPerfStats(singlePfVals::Array{Float64, 1}, dats::Array{Date, 1})
    # TODO: make use of dates array

    # get statistics that do not require dates
    perfStats, statNames = evalPerfStats(singlePfVals)
end

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

function PerfStats(vals::Array{Float64, 1}, statNams::Array{Symbol, 1})
    # preallocate
    perfStatInstance = PerfStats()

    for ii=1:length(vals)
        setfield!(perfStatInstance, statNams[ii], vals[ii])
    end

    return perfStatInstance
end
