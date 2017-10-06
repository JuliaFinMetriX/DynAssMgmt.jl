using Base.Test

fxRates = DynAssMgmt.loadTestData("fx")

# pick single column as vector
colNam = "CD"
colInd = find(fxRates.colnames .== colNam)
data = fxRates["CD"].values

# test that results of different input types are consistent
lambdaVal = 0.8
xx = DynAssMgmt.getEwmaStd(data, lambdaVal)
xx2 = DynAssMgmt.getEwmaStd(fxRates.values, lambdaVal)
xx3 = DynAssMgmt.getEwmaStd(fxRates, lambdaVal)

@test xx ≈ xx2[colInd][1]
@test xx ≈ xx3[colInd][1]
@test xx2 ≈ xx3

# test values themselves
lambdaVal = 0.9999
xx = DynAssMgmt.getEwmaStd(fxRates, lambdaVal)
xx2 = std(fxRates.values, 1)
@test xx ≈ xx2 atol=0.008

# test values for ewma mean
lambdaVal = 0.9999
xx = DynAssMgmt.getEwmaMean(fxRates, lambdaVal)
xx2 = mean(fxRates.values, 1)
@test xx ≈ xx2 atol=0.02
