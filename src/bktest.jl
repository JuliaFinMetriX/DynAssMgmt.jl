## define backtest functions

function evalPerf(someInvs::Invest, discRets::DataFrame)

    # get common dates
    jointDates = intersect(someInvs.dates, discRets[:Date])

    # get dimensions
    nObs = length(jointDates) - 1
    xx, nStrats, xx2 = size(someInvs)

    # preallocation
    perfs = zeros(Float64, nObs, nStrats)

    # get respective returns
    xxInds = findin(jointDates, discRets[:Date])
    perfDates = discRets[xxInds, :Date]
    associatedRets = discRets[xxInds, someInvs.assetLabels]
    associatedRets = convert(Array{Float64, 2}, associatedRets)

    # get respective weight rows
    xxIndsWgts = findin(jointDates, someInvs.dates)

    # adjust weights and returns for 1 period time lag
    associatedRets = associatedRets[2:end, :]
    perfDates = perfDates[2:end, :]
    xxIndsWgts = xxIndsWgts[1:end-1]

    # get respective weights
    for thisStratInd = 1:nStrats
        # get respective weights
        allWgts = convert(Array{Float64, 2}, someInvs.pfs[xxIndsWgts, thisStratInd])

        # calculate performances
        xxWgtRets = sum(allWgts .* associatedRets, 2)[:]
        pfVals = exp(cumsum(log(xxWgtRets./100 + 1)))

        # store performances
        perfs[:, thisStratInd] = pfVals
    end

    df1 = DataFrame(Date = perfDates[:])
    df2 = DataFrame(perfs)
    perfsDf = hcat(df1, df2)

end

# ddowns
function evalDDowns(perfDf::DataFrame)
    # get asset names without dates
    colNams = names(perfDf)
    assNams = setdiff(colNams, [:Date])

    # get values only
    perfVals = convert(Array, perfDf[:, assNams])

    ddownsVals = zeros(Float64, size(perfVals))
    for ii=1:size(perfVals, 2)
        ddownsVals[:, ii] = evalDDowns(perfVals[:, ii])
    end

    # build DataFrame again
    df1 = perfDf[:, [:Date]]
    df2 = DataFrame(ddownsVals)
    names!(df2, assNams)
    df = hcat(df1, df2)

    # get correct sorting
    ddownsDf = df[:, names(perfDf)]

end

function evalDDowns(perfVals::Array{Float64, 1})
    cumMaxPrices = cummax(perfVals)
    ddowns = 100*(perfVals ./ cumMaxPrices - 1)
end

## get overall performance statistics
fullPercRet(perfVals::Array{Float64, 1}) = 100*(perfVals[end] - perfVals[1])./perfVals[1]
spMu(vals::Array{Float64, 1}) = mean(vals)
spSigma(vals::Array{Float64, 1}) = std(vals)
spVaR(vals::Array{Float64, 1}, alpha::Float64) = (-1)*quantile(vals, 1-alpha)
maxDD(perfVals::Array{Float64, 1}) = (-1)*minimum(evalDDowns(perfVals))

function dailyToAnnualMuSigmaScaling(mu, sigma)
    return naive_dailyToAnnualMuSigmaScaling(mu, sigma)
end

function naive_dailyToAnnualMuSigmaScaling(mu, sigma)
    muAnnual = mu*250
    sigmaAnnual = sigma*sqrt(250)
    return muAnnual, sigmaAnnual
end

function evalPerfStats(singlePerfVals::Array{Float64, 1})
    # get returns
    singleDiscRets = (singlePerfVals[2:end] - singlePerfVals[1:end-1])./singlePerfVals[1:end-1]

    # compute performance statistics
    perfStats = Float64[]
    statNames = Symbol[]

    # full period percentage return
    push!(perfStats, fullPercRet(singlePerfVals))
    push!(statNames, :FullPercRet)

    # single period mus
    spmuval = spMu(singleDiscRets)
    push!(perfStats, spmuval)
    push!(statNames, :SpMu)

    spsigmaval = spSigma(singleDiscRets)
    push!(perfStats, spsigmaval)
    push!(statNames, :SpSigma)

    muScaled, sigmaScaled = dailyToAnnualMuSigmaScaling(spmuval, spsigmaval)
    push!(perfStats, muScaled*100)
    push!(perfStats, sigmaScaled*100)
    push!(statNames, :MuDailyToAnnualPerc)
    push!(statNames, :SigmaDailyToAnnualPerc)

    push!(perfStats, spVaR(singleDiscRets, 0.95))
    push!(statNames, :SpVaR)

    push!(perfStats, maxDD(singlePerfVals))
    push!(statNames, :MaxDD)

    return (perfStats, statNames)
end

function evalPerfStats(singlePerfVals::Array{Float64, 1}, dats::Array{Date, 1})
    # TODO: make use of dates array

    # get statistics that do not require dates
    perfStats, statNames = evalPerfStats(singlePerfVals)
end

type PerfStats
    FullPercRet::Float64
    SpMu::Float64
    SpSigma::Float64
    MuDailyToAnnualPerc::Float64
    SigmaDailyToAnnualPerc::Float64
    SpVaR::Float64
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
