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
# try gmvp
gmvpLevWgts = gmvp_lev(thisUniv)
gmvpWgts = gmvp(thisUniv)

## get portfolio moments
plot(thisUniv)

mu1, var1 = pfMoments(thisUniv, gmvpWgts)
mu2, var2 = pfMoments(thisUniv, gmvpLevWgts)
gmvpMus = [mu1, mu2]
gmvpVars = [var1, var2]
plot!(sqrt(gmvpVars)*sqrt(52), gmvpMus*52, seriestype=:scatter)

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

## do some checks
xx = sum(allGmvpWgts, 2)
bar(mean(allGmvpWgts, 1))

## compute max-sharpe portfolios

@time allMaxSharpeWgtsDistributed = map(x -> maxSharpe(x), DUnivs)
allMaxSharpeWgts = convert(Array, allMaxSharpeWgtsDistributed)
allMaxSharpeWgts = vcat([ii[:]' for ii in allMaxSharpeWgts]...)
