using Base.Test

fxRates = DynAssMgmt.loadTestData("fx")

# pick single column for vector tests
colNam = "CD"
colInd = find(fxRates.colnames .== colNam)
data = fxRates["CD"].values

## computeReturns
discRets = DynAssMgmt.computeReturns(data)
@test size(discRets, 1) == (size(data, 1) - 1)

normedPrices1 = DynAssMgmt.rets2prices(discRets)
normedPrices2 = DynAssMgmt.normalizePrices(data)
@test normedPrices1 ≈ normedPrices2[2:end]

perfs = DynAssMgmt.aggregateReturns(discRets)
fullRet = (data[end] - data[1])./data[1]
@test perfs[end] ≈ fullRet



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
