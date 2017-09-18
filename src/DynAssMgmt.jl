module DynAssMgmt

export
Invest,
gmvp,
gmvp_lev,
getUnivEvolFromMatlabFormat,
Univ,
UnivEvol,
pfMoments,
pfVariance

using DataFrames
using Convex
using DistributedArrays
using Plots
using StatPlots
using TimeSeries

#set_default_solver(SCS.SCSSolver(verbose=0))

include("utils.jl")
include("assetAllocationTypes.jl")
include("pfFuncs.jl")
include("singlePeriodStrats.jl")
include("spTargets.jl")
include("pfAPI.jl")
include("plotFuncs.jl")
include("bktest.jl")

end
