# here are the single period tests

## set up test data

fxRates = DynAssMgmt.loadTestData("fx")
fxRets = computeReturns(fxRates)

## estimate moments
ewmaEstimator = EWMA(0.95, 0.99)
xxthisUniv = apply(ewmaEstimator, fxRets)
percUniv = DynAssMgmt.getInPercentages(xxthisUniv)

## test sigma target
Plots.plot(percUniv)
Plots.plot(xxthisUniv)

sigTarget = 0.005
pf = apply(TargetVola(sigTarget), xxthisUniv)
xxMu, xxSig = pfMoments(xxthisUniv, pf, "std")
@test abs(sigTarget - xxSig) < 0.00001

sigTarget = 0.0034
pf = apply(TargetVola(sigTarget), xxthisUniv)
xxMu, xxSig = pfMoments(xxthisUniv, pf, "std")
@test abs(xxSig - sigTarget) < 0.00001

## test mu target
targetMuVal = 0.0005
pf = apply(TargetMu(targetMuVal), xxthisUniv)
xxMu, xxVar = pfMoments(xxthisUniv, pf, "var")
@test abs(xxMu - targetMuVal) < 0.000001

xxmuTarget = 0.0002
pf = apply(TargetMu(targetMuVal), xxthisUniv)
xxMu, xxVar = pfMoments(xxthisUniv, pf, "var")
@test abs(xxMu - targetMuVal) < 0.000001

## test gmvp
xxgmvp = DynAssMgmt.gmvp(xxthisUniv)
percUniv = DynAssMgmt.getInPercentages(xxthisUniv)
xxstds = sqrt.(diag(percUniv.covs))
xxMu, xxpfStd = pfMoments(xxthisUniv, xxgmvp, "std")
xxpfStdPerc = DynAssMgmt.getStdInPercentages(xxpfStd, xxthisUniv.retType)
@test all(xxVar .<= xxstds + 0.00001)
