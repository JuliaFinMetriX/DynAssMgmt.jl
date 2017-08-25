# code should be flexible with regards to
# - sub-selection of assets
# - forecast frequencies
# -

## Add required packages
Pkg.add("PyPlot")
Pkg.add("GR")
Pkg.add("UnicodePlots")
Pkg.add("PlotlyJS")
Pkg.add("StatPlots")
Pkg.add("PlotRecipes")
Pkg.add("Convex")
Pkg.add("SCS")
Pkg.add("Query")
Pkg.add("Rsvg")
Pkg.add("PDMats")
Pkg.add("BenchmarkTools")
Pkg.add("DistributedArrays")


# sadly doesn't work at the moment:
plot(muTab[:Date], muTab[:govEm_IUS7_GY_JPEICORE])

plot(getNumDates(muTab[:Date]), muTab[:govEm_IUS7_GY_JPEICORE])

# or: plot with Gadfly
thisDats = convert(Array{Date}, muTab[:Date])
Gadfly.plot(x = thisDats, y = muTab[:govEm_IUS7_GY_JPEICORE], Geom.line())

# select some date
thisDateAttempt = Date(2014, 1, 1)
thisDateInd = findfirst(muTab[:Date] .>= thisDateAttempt)
thisDate = muTab[thisDateInd, :Date]

# get global minimum variance portfolio
function gmvp(thisCovs::Array{Float64, 2})
  nObs = size(thisCovs, 1)
  identVector = ones(nObs, 1)
  invMatr = inv(thisCovs)
  gmvpWgts = (invMatr * identVector) ./ (identVector'*invMatr*identVector)
end
function gmvp(thisCovs::AbstractPDMat)
  nObs = size(thisCovs, 1)
  identVector = ones(nObs, 1)
  gmvpWgts = (thisCovs \ identVector) ./ invquad(thisCovs, identVector)
end

xxInds = covsTab[:Date] .== thisDate
thisCovs = covsTab[xxInds, 2:end]
thisCovsMatr = convert(Array{Float64}, thisCovs)
thisCovsObj = PDMat(thisCovsMatr)

@benchmark gmvp(thisCovsMatr)
@benchmark gmvp(thisCovsObj)

nDays = size(muTab, 1)
nAss = size(muTab, 2) - 1
allGmvpWgts = zeros(Float64, nDays, nAss)
Juno.progress(name = "Daily GMVP calculation") do p
for ii=1:nDays
  thisDate = muTab[:Date][ii]
  xxInds = thisDate .== covsTab[:Date]
  thisCovObj = PDMat(convert(Array{Float64, 2}, covsTab[xxInds, 2:end]))
  thisGmvpWgts = gmvp(thisCovObj)
  allGmvpWgts[ii, :] = thisGmvpWgts'
  Juno.progress(p, ii/nDays)
end
end

areaWgts = cumsum(allGmvpWgts, 2)
areaWgts = allGmvpWgts
areaWgtsTab = convert(DataFrame, areaWgts)
names!(areaWgtsTab, names(covsTab[:, 2:end]))
allAssetNames = names(areaWgtsTab)
areaWgtsTab[:Date] = muTab[:Date]

allAssetNamesString = [String(symb) for symb in allAssetNames]
Gadfly.plot(areaWgtsTab, x = "Date", y = allAssetNamesString, Geom.line())

Gadfly.plot(areaWgtsTab[:, 1:8], x=Row.index, y=Col.value, color=Col.index, Geom.line)

xxLong = stack(areaWgtsTab, allAssetNames)
Gadfly.plot(xxLong, x="Date", y="value", color="variable", Geom.line())

Gadfly.plot(xxLong, x="variable", y="value", Geom.violin())
