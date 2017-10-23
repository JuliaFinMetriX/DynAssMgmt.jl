
# coding: utf-8

# In[2]:


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
rets = Returns(xxRets, retType);

# derive associated prices
synthPrices = rets2prices(rets, 1.0, true)

function getLogPrices(prices::TimeSeries.TimeArray)
    return TimeSeries.TimeArray(prices.timestamp, log.(prices.values), prices.colnames)
end

logSynthPrices = getLogPrices(synthPrices);

# visualize universe
ewmaEstimator = EWMA(1, 1)
thisUniv = apply(ewmaEstimator, rets)

## dev plotting

assLabs = rets.data.colnames

# visualize some time series
Plots.gr()
Plots.gui()
Plots.plot(xxRets[xxRets.colnames[1:4]...], layout = (4, 1), leg=false)

# visualize universe
Plots.plot(thisUniv, doScale=false)
Plots.plot(thisUniv)

# use different built-in options
fontSpec = Plots.Font("sans-serif",6,:hcenter,:vcenter,0.0,Plots.RGB(0., 0., 0.))
figSize = (300, 300)
Plots.plot(thisUniv, label=assLabs, leg=true,
    legendfont = fontSpec, size = figSize)

pfopts(thisUniv, doScale=true, title = "Universe")
Plots.plot(PfOpts([thisUniv]), title = "Also universe") # also works

# add equal weights again
equWgtsPf = apply(EqualWgts(), thisUniv)
Plots.plot!(thisUniv, equWgtsPf, true, markershape = :star)

gmvpPf = apply(GMVP(), thisUniv)
Plots.plot(gmvpPf)
# relabeling of xaxis doesn't work
Plots.plot(gmvpPf, xlim=(1,5), xaxis=("sldkjf"), legend=true)



Plots.plot(thisUniv, equWgtsPf, true)

pfs = apply(EffFront(10), thisUniv)
Plots.plot(pfs[1])
Plots.plot(pfs[:])
DynAssMgmt.wgtsOverStrategies(pfs, leg=false)


# try call to groupedbar with seriestype
xxWgts = convert(Array{Float64, 2}, pfs[:])
xxGrid = vcat(1:size(xxWgts, 1))
Plots.plot(xxWgts, seriestype = :groupedbar, bar_position = :stack, bar_width=0.7)
# different way to do grouped bar plot
Plots.plot(StatPlots.GroupedBar((xxGrid, xxWgts)), bar_position = :stack, bar_width=0.7)


# download data
# getDataset("IndustryPfs")


# plot prices over time

#Plots.default(size = (800, 800))
#p = DynAssMgmt.tsPlot(logSynthPrices[1:200:end];
#    title = "Logarithmic prices of industry portfolios", legend = :topleft)
#Plots.xlabel!("Year")


# In[9]:


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
startInd = 22500
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

## analyse appropriateness

dayToAnalyse = 50
univToAnalyse = univHistoryShort.universes[dayToAnalyse]

Plots.plot(univToAnalyse)
univHistoryShort

divFrontSpectrum = divFrontInvs.pfs[dayToAnalyse, :]
pfMoments(univToAnalyse, divFrontSpectrum, "std")

sigTargets

gmvpPf = apply(GMVP(), univToAnalyse)
pfMoments(univToAnalyse, gmvpPf, "std")

Plots.plot(gmvpPf, label = hcat(univHistoryShort.assetLabels...), legend=true)

Plots.plot(gmvpPf)
Plots.plot(gmvpPf, univHistoryShort.assetLabels)

labs = univHistoryShort.assetLabels
Plots.plot(labs, gmvpPf.Wgts, seriestype = :bar, xrotation=45, leg=false)

Plots.plot(univToAnalyse, doAnnualize=false, label=labs, legend=true)


## plot weights over time

wgtsOverTime(divFrontInvs, 10)
annualizeRiskReturn
wgtsOverTime
# analyse weights
# - TO
# - diversification
# - average

using PyPlot
using LaTeXStrings

L"$y = \sin(x)$"

# show average diversification over time
avgDiversification = mean(pfDivers(divFrontInvs), 1)
Plots.plot(avgDiversification[:], seriestype=:bar,
    title = "Average diversification level")

# plot diversification during critical time
diversVals = pfDivers(divFrontInvs)
Plots.plot(diversVals[20:200, :])

divFrontInvs.strategies


Plots.plot(univList.universes[50])
DynAssMgmt.vizPf(univList.universes[50], divFrontInvs.pfs[50, 10])

DynAssMgmt.vizPfSpectrum(univList.universes[50], divFrontInvs.pfs[50, :][:])
wgtsOverStrategies(divFrontInvs.pfs[50, :], labels = divFrontInvs.assetLabels)


DynAssMgmt.wgtsOverStrategies(divFrontInvs.pfs[50, :],
    label = divFrontInvs.assetLabels, size = (300, 300),
    legendfont = Plots.Font("sans-serif",6,:hcenter,:vcenter,0.0,Plots.RGB(0., 0., 0.)))
Plots.gui()

dats = DynAssMgmt.getNumDates(rets.data.timestamp)
Plots.plot(dats, rets.data.values[:, 1:20], layout=(10, 2), legend = false)
using StatPlots
Plots.violin(rets.data.values[1:100, 1:4])
Plots.violin(rets.data.colnames[1:4], rets.data.values[1:100, 1:4]', leg=false)

Plots.plot(rets.data.values[1, :], seriestype = :bar, leg=false)
Plots.default(:legend)

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

@recipe function f(rets::Returns)
    x = DynAssMgmt.getNumDates(rets.data.timestamp)[:]
    y = rets.data.values
    x, y
end

nams = rets.data.colnames[1:4]
smallRets = Returns(rets.data[nams...], rets.retType)
plot(smallRets, seriestype=:line, layout=(4,1), leg=false)

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
