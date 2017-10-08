using Base.Test

fxRates = DynAssMgmt.loadTestData("fx")

# pick single column for vector tests
colNam = "CD"
colInd = find(fxRates.colnames .== colNam)
data = fxRates["CD"].values

## computeReturns, aggregateReturns and rets2prices
discRets = DynAssMgmt.computeReturns(data)
@test size(discRets, 1) == (size(data, 1) - 1)

normedPrices1 = DynAssMgmt.rets2prices(discRets, ReturnType())
normedPrices2 = DynAssMgmt.normalizePrices(data)
@test normedPrices1 ≈ normedPrices2[2:end]

normedPrices1 = DynAssMgmt.rets2prices(discRets, ReturnType(), 1.0, true)
@test normedPrices1 ≈ normedPrices2

origPrices = DynAssMgmt.rets2prices(discRets, ReturnType(), data[1], true)
@test origPrices ≈ data

perfs = DynAssMgmt.aggregateReturns(discRets, ReturnType())
fullRet = (data[end] - data[1])./data[1]
@test perfs[end] ≈ fullRet

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



# test that results of different input types are consistent
fxRets = DynAssMgmt.computeReturns(fxRates)
data = fxRets.data["CD"].values
lambdaVal = 0.8
xx = DynAssMgmt.getEwmaStd(data, lambdaVal)
xx2 = DynAssMgmt.getEwmaStd(fxRets.data.values, lambdaVal)
xx3 = DynAssMgmt.getEwmaStd(fxRets.data, lambdaVal)

@test xx ≈ xx2[colInd][1]
@test xx ≈ xx3[colInd][1]
@test xx2 ≈ xx3

# test values themselves
lambdaVal = 0.9999
xx = DynAssMgmt.getEwmaStd(fxRets.data, lambdaVal)
xx2 = std(fxRets.data.values, 1)
@test xx ≈ xx2 atol=0.0001

# test values for ewma mean
lambdaVal = 0.9999
xx = DynAssMgmt.getEwmaMean(fxRets.data, lambdaVal)
xx2 = mean(fxRets.data.values, 1)
@test xx ≈ xx2 atol=0.0001

# test values for covariance matrix
lambdaVal = 0.9999
xx = DynAssMgmt.getEwmaCov(fxRets.data, lambdaVal)
xx2 = cov(fxRets.data.values, 1)
@test xx ≈ xx2 atol=0.0001

# cross-checks
lambdaVal = 0.8
xx = DynAssMgmt.getEwmaCov(fxRets.data, lambdaVal)
xxStd1 = sqrt.(diag(xx))
xxStd2 = DynAssMgmt.getEwmaStd(fxRets.data, lambdaVal)
@test xxStd1[:] ≈ xxStd2[:]
