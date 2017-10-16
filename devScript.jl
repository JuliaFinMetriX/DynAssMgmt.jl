# test types / code during development

cd("/home/chris/scalable/julia/DynAssMgmt/")
using DynAssMgmt
using EconDatasets

# using Gadfly
# using Query
# using PDMats
# using BenchmarkTools

## set up parallel computation
addprocs(2)

## load code
@everywhere begin
    using DynAssMgmt
end

##

Plots.plotlyjs()
Plots.gr()

## load test data
fxRates = DynAssMgmt.loadTestData("fx")
fxRets = computeReturns(fxRates, ReturnType())

## plot fx-rates

DynAssMgmt.tsPlot(fxRates, doNorm = true)

## estimate moments

ewmaEstimator = EWMA(0.95, 0.99)
univList = DynAssMgmt.applyOverTime(ewmaEstimator, fxRets, 300)

## get subsets

univHistoryShort = UnivEvol(univList.universes[1:50], univList.dates[1:50],
    univList.assetLabels)
thisUniv = univList.universes[end]

## dev inPercentages

percUniv = DynAssMgmt.getInPercentages(thisUniv)
percUniv2 = DynAssMgmt.getInPercentages(percUniv)

## visualize universe with labels

Plots.plot(percUniv, univList.assetLabels)

## define efficient frontier / diversfication frontier strategies
DynAssMgmt.getUnivExtrema(thisUniv)
sigTargets = [linspace(0.003, 0.0083, 15)...]
diversTarget = 0.8

# get as strategy types
divFrontStrats = DivFront(diversTarget, sigTargets)
effFrontStrats = EffFront(10)

## apply strategies to single universe as test

divFrontWgts = apply(divFrontStrats, thisUniv)
effFrontWgts = apply(effFrontStrats, thisUniv)

## visualize outcomes

# universe together with single found portfolio
DynAssMgmt.vizPf(thisUniv, divFrontWgts[end])

# portfolio weights for single portfolio
assLabs = fxRets.data.colnames
Plots.plot(divFrontWgts[end], assLabs)

# portfolio weights for full series of portfolios
DynAssMgmt.wgtsOverStrategies(divFrontWgts)

# mu/sigma results for full series of portfolios
DynAssMgmt.vizPfSpectrum(thisUniv, effFrontWgts[:])
DynAssMgmt.vizPfSpectrum!(thisUniv, divFrontWgts[:])

## apply GMVP
gmvpPf = apply(GMVP(), thisUniv)
DynAssMgmt.vizPf(thisUniv, gmvpPf)
Plots.plot(gmvpPf)

# apply to all historic universes
@time divFrontInvs = apply(divFrontStrats, univList)
@time effFrontInvs = apply(effFrontStrats, univHistoryShort)

## evaluate performance
perfTA = DynAssMgmt.evalPerf(divFrontInvs, fxRets)

DynAssMgmt.wgtsOverTime(divFrontInvs, 10)
divFrontStrats
perfTA.values

DynAssMgmt.tsPlot(perfTA)
DynAssMgmt.tsPlot(fxRates, doNorm = true)

# calculate ddowns
ddowns = DynAssMgmt.evalDDowns(perfTA)
tsPlot(ddowns)

tsPlot(ddowns["_1"])

## plot normalized prices


## load data from disk and transform to reasonable format
rawMus = readcsv("inputData/jochenMus.csv")
rawCovs = readcsv("inputData/jochenCovs.csv")
rawIdxRets = readcsv("inputData/idxReturns.csv")

# get moments as evolution of universes
muTab = rawInputsToDataFrame(rawMus)
covsTab = rawInputsToDataFrame(rawCovs)
univHistory = getUnivEvolFromMatlabFormat(muTab, covsTab)

# get returns as TimeArray
idxRets = rawInputsToTimeArray(rawIdxRets)

## apply some strategy spectrums over time


# what can we do with investments object?
# - show weights over time
# - evaluate performance

## statistics
# - fullPercPerf
# - maxDDown
# - dailyMu
# - sigma
# - dailyVaR
# - annualizedVaR

## get backtest outcomes
# getBtOutcomes(divFrontInvs::Invest, idxRets::DataFrame, dateRange)
# Invest + idxRets + date range

# TODO: determine time period to evaluate
perfTA

# get Array of perfStats
(xx, nStrats, xx2) = size(divFrontInvs)
outcomes = PerfStats[]
for ii=1:nStrats
    vals, statisticsNams = evalPerfStats(perfTA.values[:, ii])
    perfStatisticsInstance = PerfStats(vals, statisticsNams)

    push!(outcomes, perfStatisticsInstance)
end

outcomes
divFrontInvs.strategies
divFrontInvs.assetLabels

outcomes[10]

# additional information to performance statistics:
# - which strategy (problematic with iterative weight filters)
# - which universe
# - which date range

# summarize

# export list of strategies and outcomes


# add scaled values
# - daily to annual scaling for mu / sigma

# add annualized values (also requires dates)
# - get VaR from monthly log returns
# - get geometric mean

# add yearly / monthly values

# get list of strategy names

## evalute estimated portfolio moments
# muTab, varTab = pfMoments(someInvs, univHistory)


##


##

wgtsOverStrategies(divFrontWgts, univHistory.assetLabels)


##
# investmentPerformances(allPfs, discRets)
# cumulative (weights .* returns) for each strategy with metadata
#
# wgtsEvol

# reshape
# squeeze

##

## define collection of targets
# - over time
# - over targets
# - list of dates
# - list of assets
# - list of targets
#
# - switch between "cross-section" and "over time" perspective
# - overTime vs overTargets
#
# - nObs x nStrats x nAss,
#   where nStrats is possibly grouped into sub-groups (e.g. due to spectra)


##
# inspect days with too much deviation
xxIndsToInspect = find(.!xxCloseEnough)
closeToMaxSigAss = []
for ii in xxIndsToInspect
    xxthisUniv = univHistory.universes[ii]

    # find maximum mu
    xx, xxInd = findmax(xxthisUniv.mus)

    # get associated sigma
    maxSigAsset = sqrt.(diag(xxthisUniv.covs)[xxInd])

    # compare to sigma target portfolio
    foundSigma = sqrt.(dailyVars[ii])

    push!(closeToMaxSigAss, abs(foundSigma - maxSigAsset) < 0.01)
end
closeToMaxSigAss = convert(BitArray, closeToMaxSigAss)
indsToInspect = xxIndsToInspect[.!closeToMaxSigAss]

##

indsToInspect = [280, 621, 724, 1633, 1757, 3624]
sqrt.(dailyVars[indsToInspect])

##

xx1 = sigmaTarget(univHistory.universes[280], sigTarget)

## visualize universe
thisUnivInd = 280
thisUniv = univHistory.universes[thisUnivInd]
plot(thisUniv)
vizPf!(thisUniv, allSigWgts[thisUnivInd, :])
#plot(thisUniv, univHistory.assetLabels)

##


##
# try gmvp
gmvpLevWgts = gmvp_lev(thisUniv)
gmvpWgts = gmvp(thisUniv)

##

sigTarget = 1.7
targetSigWgts = sigmaTarget(thisUniv, sigTarget)
xxMu, xxVar = pfMoments(thisUniv, targetSigWgts)
sqrt(xxVar)

##

targetMu = 0.06
targetMuWgts = muTarget(thisUniv, targetMu)
pfMoments(thisUniv, targetMuWgts)

getUnivExtrema(thisUniv)

## get portfolio moments
vizPf(thisUniv, gmvpWgts)
vizPf!(thisUniv, targetSigWgts)
vizPf!(thisUniv, targetMuWgts)

## plot portfolio moments for single pf over time
allPfMus, allPfVars = pfMoments(univHistory, gmvpLevWgts)
plot(sqrt.(allPfVars)*sqrt.(52), allPfMus.*52, xaxis="Sigma",
    yaxis="Mu", labels = "GMVP")

allPfMus, allPfVars = pfMoments(univHistory, gmvpWgts)
plot!(sqrt.(allPfVars)*sqrt.(52), allPfMus.*52, xaxis="Sigma",
    yaxis="Mu", labels = "GMVP", color=:red)

@time allGmvpWgtsDistributed = map(x -> gmvp(x), DUnivs)
allGmvpWgts = convert(Array, allGmvpWgtsDistributed)
allGmvpWgts = vcat([ii[:]' for ii in allGmvpWgts]...)

sigTarget = 1.12
@time allSigWgtsDistributed = map(x -> cappedSigma(x, sigTarget), DUnivs)
allSigWgts = convert(Array, allSigWgtsDistributed)
allSigWgts = vcat([ii[:]' for ii in allSigWgts]...)
