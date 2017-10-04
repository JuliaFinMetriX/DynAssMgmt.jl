# here are the single period tests

## set up test data
xxCovs = readdlm("testData/testCovs.csv")
xxMus = readdlm("testData/testMus.csv")
xxMus = xxMus[:]

xxthisUniv = Univ(xxMus, xxCovs)

## test sigma target

sigTarget = 1.7
targetSigWgts = DynAssMgmt.sigmaTarget(xxthisUniv, sigTarget)
xxMu, xxSig = pfMoments(xxthisUniv, targetSigWgts, "std")
@test abs(xxSig - sigTarget) < 0.01

sigTarget = 0.3
targetSigWgts = DynAssMgmt.sigmaTarget(xxthisUniv, sigTarget)
xxMu, xxSig = pfMoments(xxthisUniv, targetSigWgts, "std")
@test abs(xxSig - sigTarget) < 0.01

## test mu target
xxmuTarget = 0.1
xxWgts = DynAssMgmt.muTarget(xxthisUniv, xxmuTarget)
xxMu, xxVar = pfMoments(xxthisUniv, xxWgts, "var")
@test abs(xxMu - xxmuTarget) < 0.0001

xxmuTarget = 0.02
xxWgts = DynAssMgmt.muTarget(xxthisUniv, xxmuTarget)
xxMu, xxVar = pfMoments(xxthisUniv, xxWgts, "var")
@test abs(xxMu - xxmuTarget) < 0.0001


## test gmvp
xxgmvp = DynAssMgmt.gmvp(xxthisUniv)
xxMu, xxVar = pfMoments(xxthisUniv, xxgmvp, "var")
@test all(xxVar .<= diag(xxthisUniv.covs) + 0.0001)
