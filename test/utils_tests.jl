using Base.Test

# test loading of test data
@test_throws Exception DynAssMgmt.loadTestData("dkflsj")
@test isa(DynAssMgmt.loadTestData("fx"), TimeSeries.TimeArray)

# locf!(xx::Array{Float64, 1})
xx = [4.2; NaN; 6.5; 4.3; NaN; NaN; 8.0]
DynAssMgmt.locf!(xx)
@test xx == [4.2; 4.2; 6.5; 4.3; 4.3; 4.3; 8.0]

# locf(xx::Array{Float64, 1})
xx = [4.2; NaN; 6.5; 4.3; NaN; NaN; 8.0]
xx2 = DynAssMgmt.locf(xx)
xx
@test xx2 == [4.2; 4.2; 6.5; 4.3; 4.3; 4.3; 8.0]
# should not alter the original xx
@test isnan(xx[2])
@test isnan(xx[5])
@test xx[7] == 8.0

# locf(xx::Array{Float64, 2})
xx = [4.2; NaN; 6.5; 4.3; NaN; NaN; 8.0]
xx = repmat(xx, 1, 5)
expOut = repmat([4.2; 4.2; 6.5; 4.3; 4.3; 4.3; 8.0], 1, 5)
@test DynAssMgmt.locf(xx) == expOut

# nocb!
xx = [NaN; 6.5; 4.3; NaN; NaN; 8.0]
@test DynAssMgmt.nocb!(xx) == [6.5; 6.5; 4.3; 8.0; 8.0; 8.0]

# normalizePrices
xx = [100; 120; 200.0]
expOut = [1; 1.2; 2]
@test normalizePrices(xx) == expOut

# with missing observation at beginning
xx = [NaN; 100; 120; 200.0]
expOut = [NaN; 1; 1.2; 2]
actOut = normalizePrices(xx)
@test isnan(actOut[1])
@test actOut[2:end] == expOut[2:end]
