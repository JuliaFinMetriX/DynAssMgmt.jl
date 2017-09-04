using Base.Test

# load own code
include("../src/utils.jl")
include("../src/assetAllocationTypes.jl")
include("../src/plotFuncs.jl")
include("../src/pfFuncs.jl")
include("../src/singlePeriodStrats.jl")


@testset "Tests of single period strategies" begin include("singlePeriodStrats_tests.jl") end
