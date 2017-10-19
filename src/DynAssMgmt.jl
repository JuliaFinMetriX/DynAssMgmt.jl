module DynAssMgmt

export
    ReturnType,
    Returns,
    Invest,
    PF,
    SinglePeriodTarget,
    SinglePeriodSpectrum,
    Univ,
    UnivEvol,
    UnivEstimator,
    EWMA,
    EqualWgts,
    GMVP,
    TargetVola,
    RelativeTargetVola,
    MaxSharpe,
    TargetMu,
    EffFront,
    DivFrontSigmaTarget,
    DivFront,
    apply,
    applyOverTime,
    pfMoments,
    pfDivers,
    normalizePrices,
    getEwmaMean,
    getEwmaStd,
    getEwmaCov,
    getInPercentages,
    annualizeRiskReturn,
    standardizeReturns,
    computeReturns,
    aggregateReturns,
    rets2prices,
    wgtsOverTime,
    wgtsOverStrategies

using DataFrames
using Convex
using SCS
using DistributedArrays

ENV["PLOTS_USE_ATOM_PLOTPANE"] = "false"
using Plots

using StatPlots
using TimeSeries
using IterableTables
using RDatasets

set_default_solver(SCS.SCSSolver(verbose=0))

include("utils.jl")
include("baseEconMetrics.jl")
include("universeTypes.jl")
include("singlePeriodStrats.jl")
include("spTargets.jl")
include("pfAPI.jl")
include("pfFuncs.jl")
include("plotFuncs.jl")
include("bktest.jl")

end
