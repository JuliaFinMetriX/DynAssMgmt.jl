# TODO
# - run backtests on large data
# - allow universe subsets
# - inspect moment estimators directly
# - implement weight filters
# - save and load portfolios
# - check optimization status to catch errors
# - identify failed strategies and inspect them


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
using NamedArrays
using JLD

# load data
xxRets = dataset("IndustryPfs")

# store with information regarding the return type
retType = ReturnType(true, false, Dates.Day(1), false)
rets = Returns(xxRets, retType)

## define efficient frontier / diversfication frontier strategies
sigTargets = [linspace(.7, 1.4, 15)...]
diversTarget = 0.9
divFrontStrat = DivFront(diversTarget, sigTargets)

## estimate historic moments
ewmaEstimator = EWMA(0.99, 0.95)
# startInd = 500
startInd = findfirst(rets.data.timestamp .>= Date(1950,1,1))
@time univList = DynAssMgmt.applyOverTime(ewmaEstimator, rets, startInd)

# get subsets
univHistoryShort = UnivEvol(univList.universes[1:50], univList.dates[1:50],
    univList.assetLabels)
btUniverses = univList

## backtest strategies
divFrontInvs = apply(divFrontStrat, btUniverses)
equWgtsInvs = apply(DynAssMgmt.EqualWgts(), btUniverses)

## evaluate performance
perfs = evalPerf(divFrontInvs, rets)
equWgtsPerfs = evalPerf(equWgtsInvs, rets)

## impute NaNs
oldPerfs = perfs
xx = DynAssMgmt.locf(perfs.data.values)
xxTA = TimeArray(perfs.data.timestamp, xx, perfs.data.colnames)
perfs = Performances(xxTA, perfs.retType)

# show performances
# Plots.gui()
# Plots.plot(perfs, leg=:topleft)
# Plots.plot!(equWgtsPerfs.data.timestamp, equWgtsPerfs.data.values*100, lab="Equal weights", line = (2, :red))

## get drawdowns
ddowns = evalDDowns(perfs)
Plots.plot(ddowns, leg=:bottomright)
Plots.gui()

## compute performance measures
perfStats = evalPerfStats(perfs)
perfSummary = DynAssMgmt.getPerfStatSummary(perfs)

## compute performance measures for underlying assets
xxInds = rets.data.timestamp .>= perfs.data.timestamp[1]
btAssRets = Returns(rets.data[xxInds], rets.retType)
assPerfs = convert(Performances, btAssRets)
assPerfStats = DynAssMgmt.getPerfStatSummary(assPerfs)

## compute performance measures for equal weights
equWgtsSummary = DynAssMgmt.getPerfStatSummary(equWgtsPerfs)

##
Plots.plot(perfSummary[:, "MaxDD"], perfSummary[:, "MuDailyToAnnualPerc"], seriestype = :scatter,
    xlabel="Maximum drawdown", ylabel="Annual percentage return", labels="Strategies")
Plots.plot!(assPerfStats[:, "MaxDD"], assPerfStats[:, "MuDailyToAnnualPerc"], seriestype = :scatter,
    labels="Assets")
Plots.plot!(equWgtsSummary[:, "MaxDD"], equWgtsSummary[:, "MuDailyToAnnualPerc"], seriestype = :scatter,
    labels="Equal weights")
Plots.gui()

Plots.plot(perfSummary[:, "SigmaDailyToAnnualPerc"], perfSummary[:, "MuDailyToAnnualPerc"], seriestype = :scatter,
    xlabel="Annual percentage vola", ylabel="Annual percentage return", labels="Strategies")
Plots.plot!(assPerfStats[:, "SigmaDailyToAnnualPerc"], assPerfStats[:, "MuDailyToAnnualPerc"], seriestype = :scatter,
    labels="Assets")
Plots.plot!(equWgtsSummary[:, "SigmaDailyToAnnualPerc"], equWgtsSummary[:, "MuDailyToAnnualPerc"], seriestype = :scatter,
    labels="Equal weights")
Plots.gui()

## write portfolios to file
save("./tmp/divFrontInvestments.jld", "divFrontInvs", divFrontInvs)


##
divFrontInvsLoaded = load("./tmp/divFrontInvestments.jld", "divFrontInvs")
divFrontInvsLoaded = load("./tmp/divFrontInvestments.jld")
divFrontInvs = divFrontInvsLoaded["divFrontInvs"]
