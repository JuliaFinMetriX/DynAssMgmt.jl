## set up parallel computation
addprocs(3)

## load code
@everywhere begin
    using DynAssMgmt
end

## setup

ENV["PLOTS_USE_ATOM_PLOTPANE"] = "false"
using Plots
using DynAssMgmt
using EconDatasets
using TimeSeries

# load data
xxRets = dataset("IndustryPfs")

# store with information regarding the return type
retType = ReturnType(true, false, Dates.Day(1), false)
rets = Returns(xxRets, retType)

Plots.gui()

## define efficient frontier / diversfication frontier strategies
sigTargets = [linspace(.7, 1.4, 15)...]
diversTarget = 0.9
divFrontStrat = DivFront(diversTarget, sigTargets)

## estimate historic moments
ewmaEstimator = EWMA(0.99, 0.95)
startInd = 22500
@time univList = DynAssMgmt.applyOverTime(ewmaEstimator, rets, startInd)

# get subsets
univHistoryShort = UnivEvol(univList.universes[1:50], univList.dates[1:50],
    univList.assetLabels)
btUniverses = univList

## backtest strategies
divFrontInvs = apply(divFrontStrat, btUniverses)
equWgtsInvs = apply(DynAssMgmt.EqualWgts(), btUniverses)

## inspect chosen portfolios
xxInd = 10
sigTarget = divFrontStrat.sigTargets[xxInd]
stratName = "Sigma target $sigTarget"
wgtsOverTime(divFrontInvs, xxInd, leg=false, title = stratName)

# analyse diversification levels
diversVals = pfDivers(divFrontInvs)
stratLabels = [*("Sigma", " $sigTarget") for sigTarget in divFrontStrat.sigTargets]
Plots.plot(divFrontInvs.dates, diversVals, labels = stratLabels)

# show average diversification over time
avgDiversification = mean(diversVals, 1)
Plots.plot(stratLabels, avgDiversification[:], seriestype=:bar, leg=false,
    xrotation = 45, xlabel = "Strategy", title = "Average diversification level", )

# analyse sigma levels
divFrontInvs
nDays, nStrats, nAss = size(divFrontInvs)
allCondSigs = zeros(nDays, nStrats)
for ii=1:nDays
    for jj=1:nStrats
        mu, sig = pfMoments(btUniverses.universes[ii], divFrontInvs.pfs[ii, jj], "std")
        allCondSigs[ii, jj] = sig
    end
end

Plots.plot(divFrontInvs.dates, allCondSigs, labels = stratLabels)

## analyse single peculiar universe
dayToAnalyse = 50
univToAnalyse = btUniverses.universes[dayToAnalyse]

pfopts(univToAnalyse, doScale=true)

## evaluate performance
perfs = DynAssMgmt.evalPerf(divFrontInvs, rets)
equWgtsPerfs = DynAssMgmt.evalPerf(equWgtsInvs, rets)

# rename performance columns
xx = rename(perfs.data, stratLabels)
perfs = Performances(xx, perfs.retType)

# show performances
Plots.plot(perfs, leg=:topleft)
Plots.plot!(equWgtsPerfs.data.timestamp, equWgtsPerfs.data.values*100, lab="Equal weights", line = (2, :red))

## get drawdowns
ddowns = DynAssMgmt.evalDDowns(perfs)
Plots.plot(ddowns, leg=:bottomright)

## compute performance measures
perfStats = evalPerfStats(perfs)

prices = convert(Prices, perfs)
stdPrices = standardize(prices)

nObs, nTimeSeries = size(prices.data.values)
allPerfStats = Array(PerfStats, nTimeSeries)
for ii=1:nTimeSeries
    xxVals, xxNams = evalPerfStats(prices.data.values[:, ii])
    thisPerfStats = DynAssMgmt.PerfStats(xxVals, xxNams)
    allPerfStats[ii] = thisPerfStats
end

allPerfStats.FullPercRet

allFields = fieldnames(allPerfStats[1])
nMetrics = length(allFields)
nStrats = length(allPerfStats)
metricsSummary = zeros(Float64, nStrats, nMetrics)
for ii=1:nStrats
    thisResults = allPerfStats[ii]
    for jj=1:nMetrics
        metricsSummary[ii, jj] = getfield(thisResults, allFields[jj])
    end
end

metricsNames = String[thisField for thisField in allFields]
xx = NamedArray(metricsSummary, (stratLabels, metricsNames), ("Strategies", "Metrics"))

convert(Array{Float64, 1}, xx[:, "FullPercRet"])


Plots.plot(xx[:, "SigmaDailyToAnnualPerc"], xx[:, "MuDailyToAnnualPerc"], seriestype = :scatter)
Plots.plot(xx[:, "MaxDD"], xx[:, "MuDailyToAnnualPerc"], seriestype = :scatter)



using NamedArrays

function getRealizedRiskReturn(prices::TimeSeries.TimeArray)

    nStrats = size(prices.values, 2)
    allPerfStats = []
    for ii=1:nStrats
        xxVals, xxNams = DynAssMgmt.evalPerfStats(prices.values[:, ii])
        thisPerfStats = DynAssMgmt.PerfStats(xxVals, xxNams)
        push!(allPerfStats, thisPerfStats)
    end

    # extract mus and sigmas
    stratMus = [thisStrat.MuDailyToAnnualPerc for thisStrat in allPerfStats]
    stratSigmas = [thisStrat.SigmaDailyToAnnualPerc for thisStrat in allPerfStats]

    return stratMus, stratSigmas
end

xxInds = rets.data.timestamp .>= realizedPrices.data.timestamp[1]
btAssRets = Returns(rets.data[xxInds], rets.retType)
assPrices = convert(Prices, btAssRets)
assMus, assSigmas = getRealizedRiskReturn(assPrices.data)
Plots.plot(assSigmas, assMus, seriestype = :scatter, label="Assets")

realizedPrices = convert(Prices, perfs)
stratMus, stratSigmas = getRealizedRiskReturn(realizedPrices.data)
Plots.plot!(stratSigmas, stratMus, seriestype = :scatter, label="Strategies")

equWgtsPrices = convert(Prices, equWgtsPerfs)
equWgtsMus, equWgtsSigmas = getRealizedRiskReturn(equWgtsPrices.data)
Plots.plot!(equWgtsSigmas, equWgtsMus, seriestype = :scatter, label="Equal weights")

##

prices = convert(Prices, perfs)
xxVals, xxNams = DynAssMgmt.evalPerfStats(prices.data.values[:, 5])
thisPerfStats = DynAssMgmt.PerfStats(xxVals, xxNams)


# analyse weights
# - TO
# - diversification
# - average

using PyPlot
using LaTeXStrings

L"$y = \sin(x)$"


using Plots
dats = DynAssMgmt.getNumDates(logSynthPrices.timestamp)
anim = Plots.@animate for ii=1:500:length(dats)
    Plots.plot(dats[1:ii], logSynthPrices.values[1:ii, :], leg=false)
end

animGif = Plots.@gif for ii=1:100:length(dats)
    Plots.plot(dats[1:ii], logSynthPrices.values[1:ii, :], leg=false)
end

gui(animGif)
display(animGif)
