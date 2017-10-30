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

## dev of conversions
perfs = convert(Performances, rets)
retsAgain = convert(Returns, perfs)

perfs.data.values[1:10, 1:4]
perfs.retType
DynAssMgmt.tsPlot(perfs.data)
Plots.gui()

synthPrices = convert(Prices, rets)
logSynthPrices = getLogPrices(synthPrices)
DynAssMgmt.tsPlot(logSynthPrices.data)
Plots.gui()

vals = rets.data.values
vals = exp(cumsum(log.(1 + vals / 100))) - 1
Plots.plot(vals)

# visualize returns
# shortRets = Returns(rets.data[end-1000:end], rets.retType)
# xx = shortRets.data[shortRets.data.colnames[1:8]...]
# shortRets = Returns(xx, rets.retType)
# Plots.plot(shortRets, layout=(4, 2), leg=false)

# estimate overall moments
fullUniv = apply(EWMA(1, 1), rets)

## find appropriate targets for strategies

# get extreme asset moments
DynAssMgmt.getUnivExtrema(fullUniv)

# get risk of gmvp
gmvpPf = apply(GMVP(), fullUniv)
pfMoments(fullUniv, gmvpPf, "std")

# visualize portfolio opportunities
pfopts(fullUniv, doScale = false)
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



any(isnan(perfTA.values))

# quick hack to eliminate NaNs
xxGoodInds = !any(isnan(perfTA.values), 1)

xxVals = perfTA.values[:, xxGoodInds[:]]
perfTA = TimeSeries.TimeArray(perfTA.timestamp, xxVals, perfTA.colnames[xxGoodInds[:]])

function perf2prices(perfs::TimeSeries.TimeArray)
    prices = perfs.values + 1
    return TimeSeries.TimeArray(perfs.timestamp, prices, perfs.colnames)
end

# In[ ]:

# DynAssMgmt.wgtsOverTime(divFrontInvs, 10)


# In[ ]:

#DynAssMgmt.tsPlot(perfTA)
correspondingPrices = synthPrices[startInd:end]
xx = computeReturns(correspondingPrices, ReturnType())
assPerfs = aggregateReturns(xx, false)
#DynAssMgmt.tsPlot(assPerfs; doNorm = false, legend = :bottomleft)

assDdowns = DynAssMgmt.evalDDowns(correspondingPrices)
# DynAssMgmt.tsPlot(assDdowns)

# In[ ]:

# calculate ddowns
pricesTA = perf2prices(perfTA)



ddowns = DynAssMgmt.evalDDowns(pricesTA)
#DynAssMgmt.tsPlot(ddowns)

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

assMus, assSigmas = getRealizedRiskReturn(correspondingPrices)
Plots.plot(assSigmas, assMus, seriestype = :scatter)

stratMus, stratSigmas = getRealizedRiskReturn(pricesTA)
Plots.plot!(stratSigmas, stratMus, seriestype = :scatter)

equWgtsPricesTA = perf2prices(equWgtsPerfTA)
equWgtsMus, equWgtsSigmas = getRealizedRiskReturn(equWgtsPricesTA)
Plots.plot!(equWgtsSigmas, equWgtsMus, seriestype = :scatter)


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
