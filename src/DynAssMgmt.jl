module DynAssMgmt

export
    ReturnType,
    Returns,
    Prices,
    Performances,
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
    getLogPrices,
    getDiscretePrices,
    normalizePrices,
    getEwmaMean,
    getEwmaStd,
    getEwmaCov,
    getInPercentages,
    annualizeRiskReturn,
    standardize,
    computeReturns,
    aggregateReturns,
    rets2prices,
    wgtsOverTime,
    wgtsOverStrategies,
    pfopts,
    evalPerf,
    evalDDowns,
    evalPerfStats,
    PerfStats

using DataFrames
using Convex
using SCS
using DistributedArrays

ENV["PLOTS_USE_ATOM_PLOTPANE"] = "false"
using Plots

using StatPlots
#using RecipesBase
using TimeSeries
using IterableTables
using RDatasets
using NamedArrays

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
