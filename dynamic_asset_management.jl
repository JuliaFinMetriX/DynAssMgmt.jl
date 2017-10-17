
# coding: utf-8

# In[2]:


## set up parallel computation
addprocs(2)

## load code
@everywhere begin
    using DynAssMgmt
end

using DynAssMgmt
using EconDatasets
using TimeSeries


# Use `EconDatasets` package to download return data on Fama / French industry portfolios

# In[3]:

# download data
# getDataset("IndustryPfs")


# Load the industry return data in raw version

# In[4]:

# load data
xxRets = dataset("IndustryPfs");


# Transform into more robust data type

# In[5]:

size(xxRets.values)


# In[6]:

# store with information regarding the return type
retType = ReturnType(true, false, Dates.Day(1), false)
rets = Returns(xxRets, retType);


# In[7]:

# derive associated prices
synthPrices = rets2prices(rets, 1.0, true)

function getLogPrices(prices::TimeSeries.TimeArray)
    return TimeSeries.TimeArray(prices.timestamp, log.(prices.values), prices.colnames)
end

logSynthPrices = getLogPrices(synthPrices);


# In[8]:

# plot prices over time
Plots.gr()

#Plots.default(size = (800, 800))
#p = DynAssMgmt.tsPlot(logSynthPrices[1:200:end];
#    title = "Logarithmic prices of industry portfolios", legend = :topleft)
#Plots.xlabel!("Year")


# In[9]:

# visualize universe
ewmaEstimator = EWMA(1, 1)
thisUniv = apply(ewmaEstimator, rets)

# test equal weights
DynAssMgmt.apply(DynAssMgmt.EqualWgts(), thisUniv)

# Plots.plotlyjs()
#Plots.default(size = (800, 700))
#Plots.plot(thisUniv, rets.data.colnames)


# In[10]:

## define efficient frontier / diversfication frontier strategies
DynAssMgmt.getUnivExtrema(thisUniv)


# In[11]:

sigTargets = [linspace(.8, 1.4, 15)...]

# get efficient frontier
effFrontStrats = EffFront(10)
#effFrontWgts = apply(effFrontStrats, thisUniv)

# get as strategy types
diversTarget = [0.6:0.1:0.9...]
diversTarget = [0.9]
divFrontStrats = [DivFront(thisDivTarget, sigTargets) for thisDivTarget in diversTarget]
#divFrontWgts = [apply(thisStrat, thisUniv) for thisStrat in divFrontStrats]

# In[12]:

## mu/sigma results for full series of portfolios
#Plots.gr()
#DynAssMgmt.vizPfSpectrum(thisUniv, effFrontWgts[:])
#for thisDivFront in divFrontWgts
#    p = DynAssMgmt.vizPfSpectrum!(thisUniv, thisDivFront[:])
#end
#p


# In[13]:

#Plots.gr()
#DynAssMgmt.wgtsOverStrategies(divFrontWgts[end])


# In[14]:

## estimate moments
ewmaEstimator = EWMA(0.99, 0.95)
startInd = 1
@time univList = DynAssMgmt.applyOverTime(ewmaEstimator, rets, startInd)

# In[ ]:

## get subsets
univHistoryShort = UnivEvol(univList.universes[1:50], univList.dates[1:50],
    univList.assetLabels)
univHistoryShort = univList


thisStrat = divFrontStrats[end]
divFrontInvs = apply(thisStrat, univHistoryShort)

thisStrat = DynAssMgmt.EqualWgts()
equWgtsInvs = apply(thisStrat, univHistoryShort)

# In[ ]:

## evaluate performance
perfTA = DynAssMgmt.evalPerf(divFrontInvs, rets)
equWgtsPerfTA = DynAssMgmt.evalPerf(equWgtsInvs, rets)

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
