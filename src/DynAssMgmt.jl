module DynAssMgmt

export
    Invest,
    PF,
    SinglePeriodTarget,
    SinglePeriodSpectrum,
    Univ,
    UnivEvol,
    EWMA,
    GMVP,
    TargetVola,
    RelativeTargetVola,
    MaxSharpe,
    TargetMu,
    EffFront,
    DivFrontSigmaTarget,
    DivFront,
    apply,
    pfMoments,
    pfDivers,
    normalizePrices,
    getEwmaMean,
    getEwmaStd,
    getEwmaCov,
    computeReturns,
    aggregateReturns,
    rets2prices

using DataFrames
using Convex
using DistributedArrays
using Plots
using StatPlots
using TimeSeries
using IterableTables
using RDatasets

#set_default_solver(SCS.SCSSolver(verbose=0))

include("utils.jl")
include("universeTypes.jl")
include("pfFuncs.jl")
include("baseEconMetrics.jl")
include("singlePeriodStrats.jl")
include("spTargets.jl")
include("pfAPI.jl")
include("plotFuncs.jl")
include("bktest.jl")

end
