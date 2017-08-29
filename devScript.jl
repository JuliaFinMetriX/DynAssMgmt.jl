# test types / code during development

cd("/home/chris/scalable/julia/DynAssMgmt/")

# using Gadfly
# using Query
# using PDMats
# using BenchmarkTools

## set up parallel computation
addprocs(2)

## load code
@everywhere begin
    using DataFrames
    using Convex
    using DistributedArrays
    using Plots

    include("src/utils.jl")
    include("src/assetAllocationTypes.jl")
    include("src/plotFuncs.jl")
    include("src/pfFuncs.jl")
    include("src/singlePeriodStrats.jl")
end

##

plotlyjs()

## load data from disk and transform to reasonable format
rawMus = readcsv("inputData/jochenMus.csv")
rawCovs = readcsv("inputData/jochenCovs.csv")
rawIdxRets = readcsv("inputData/idxReturns.csv")

muTab = rawInputsToDataFrame(rawMus)
covsTab = rawInputsToDataFrame(rawCovs)
idxRets = rawInputsToDataFrame(rawIdxRets)

## get as evolution of universes
univHistory = getUnivEvolFromMatlabFormat(muTab, covsTab)

## visualize universe
thisUniv = univHistory.universes[end]
plot(thisUniv)
plot(thisUniv, univHistory.assetLabels)

##


##
# try gmvp
gmvpLevWgts = gmvp_lev(thisUniv)
gmvpWgts = gmvp(thisUniv)

sigTarget = 1.12
targetSigWgts = cappedSigma(thisUniv, sigTarget)
xxMu, xxVar = pfMoments(thisUniv, targetSigWgts)
sqrt(xxVar)

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

## do parallel computation
DUnivs = distribute(univHistory.universes)

@time allGmvpWgtsDistributed = map(x -> gmvp(x), DUnivs)
allGmvpWgts = convert(Array, allGmvpWgtsDistributed)
allGmvpWgts = vcat([ii[:]' for ii in allGmvpWgts]...)

sigTarget = 1.12
@time allSigWgtsDistributed = map(x -> cappedSigma(x, sigTarget), DUnivs)
allSigWgts = convert(Array, allSigWgtsDistributed)
allSigWgts = vcat([ii[:]' for ii in allSigWgts]...)

## make area plot for weights
xxGrid = univHistory.dates
xxDats = getNumDates(xxGrid)
xxLabs = univHistory.assetLabels

default(show = true, size=(1400,800))
p = wgtsOverTime(allSigWgts, xxDats, xxLabs)
display(p)

# plot first weights

## get portfolio sigma for each day

nObs = size(allSigWgts, 1)
dailyPfSigs = zeros(Float64, nObs)
for ii=1:nObs
    thisUniv = univHistory.universes[ii]

    thisWgts = allSigWgts[ii, :]
    mu, pfvar = pfMoments(thisUniv, thisWgts[:])

    dailyPfSigs[ii] = sqrt(pfvar)

end

plot(dailyPfSigs)

## do some checks
xx = sum(allSigWgts, 2)
bar(mean(allSigWgts, 1))

##

@userplot PortfolioComposition

# this shows the shifting composition of a basket of something over a variable
# - "returns" are the dependent variable
# - "weights" are a matrix where the ith column is the composition for returns[i]
# - since each polygon is its own series, you can assign labels easily
@recipe function f(pc::PortfolioComposition)
    weights, returns = pc.args
    n = length(returns)
    weights = cumsum(weights,2)
    seriestype := :shape

	# create a filled polygon for each item
    for c=1:size(weights,2)
        sx = vcat(weights[:,c], c==1 ? zeros(n) : reverse(weights[:,c-1]))
        sy = vcat(returns, reverse(returns))
        @series Plots.isvertical(d) ? (sx, sy) : (sy, sx)
    end
end

tickers = ["IBM", "Google", "Apple", "Intel"]
N = 10
D = length(tickers)
weights = rand(N,D)
weights ./= sum(weights, 2)
returns = sort!((1:N) + D*randn(N))

portfoliocomposition(weights, returns, labels = tickers)

##

plot([0, 0, 1, 1], [0, 1, 1, 0], seriestype=:shape)

##

plot([1.; xxGrid[1:3]; 3], [0.; ones(3); 0], seriestype=:shape)

##
xxGrid = Float64[ii for ii=1:size(allSigWgts, 1)]
xxGrid = [1.; xxGrid; 1.]
plot([1.; xxGrid; xxGrid[end]+1], [0; allSigWgts[:, 1]; 0], seriestype=:shape)

## compute max-sharpe portfolios

@time allMaxSharpeWgtsDistributed = map(x -> maxSharpe(x), DUnivs)
allMaxSharpeWgts = convert(Array, allMaxSharpeWgtsDistributed)
allMaxSharpeWgts = vcat([ii[:]' for ii in allMaxSharpeWgts]...)
