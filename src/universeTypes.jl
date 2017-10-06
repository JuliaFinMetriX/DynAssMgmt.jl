# types and functions relating to the financial environment
# - mu / sigma / covariance container
# - mu / sigma / covariance estimator

"""
    Univ(mus, covs)

Universe type, built on Float64 arrays. The universe specifies
discrete asset moments: mus and covs.
"""
struct Univ
    mus::Array{Float64, 1}
    covs::Array{Float64, 2}
end

function getUnivExtrema(thisUniv)
    muRange = extrema(thisUniv.mus)
    sigRange = extrema(sqrt.(diag(thisUniv.covs)))
    muRange, sigRange
    xx = [muRange[1] muRange[2]; sigRange[1] sigRange[2]]
end

import Base.size
"""
    size(thisUniv)

Number of assets in Universe
"""
function size(thisUniv::Univ)
    length(thisUniv.mus)
end

"""
    UnivEvol(manyUnivs, manyDates, assetLabels)

Robust implementation of series of universes. In contrast to a
simple array of Univs, a UnivEvol also contains metadata like
dates and asset names.
"""
struct UnivEvol
    universes::Array{Univ, 1}
    dates::Array{Date, 1}
    assetLabels::Array{Symbol, 1}
end

"""
    size(thisUnivEvol)

Number of dates x number of assets of universe evolution
"""
function size(thisUnivEvol::UnivEvol)
    (length(thisUnivEvol.dates), length(thisUnivEvol.assetLabels))
end

## estimator types

abstract type UnivEstimator end

"""
    EWMA(muPersistence::Float64, covPersistence::Float64)

Exponential weighted moving average estimator of asset moments.
`muPersistence` is the lambda value of the estimator of mean asset returns,
and `covPersistence` is the lambda value for the covariance matrix.
"""
struct EWMA
    muPersistence::Float64
    covPersistence::Float64
end

function apply(thisEstimator::UnivEstimator, discRets::TimeSeries.TimeArray})


end


## derive series of financial environments from matlab .csv files

"""
    getUnivEvolFromMatlabFormat(musTab, covsTab)

Transform Matlab long format of estimated moments into UnivEvol type.
"""
function getUnivEvolFromMatlabFormat(muTab::DataFrame, covsTab::DataFrame)
    # get list of assets
    assNames = setdiff(names(muTab), [:Date])

    # get list of dates
    allDats = unique(muTab[:Date])

    univList = []

    # directly extract dates as Date Arrays
    allMuDats = convert(Array{Date, 1}, muTab[:Date])
    allCovsDats = convert(Array{Date, 1}, covsTab[:Date])

    # directly extract values
    allMusValues = convert(Array{Float64, 2}, muTab[:, assNames])
    allCovsValues = convert(Array{Float64, 2}, covsTab[:, assNames])

    # loop over individual days to set up list of Universes
    for ii=1:length(allDats)
        # get current date
        thisDat = allDats[ii]

        # get current values of moments
        thisDatMus = allMusValues[allMuDats .== thisDat, :]
        thisDatCovs = allCovsValues[allCovsDats .== thisDat, :]

        # get values in correct format
        muVals = convert(Array{Float64}, thisDatMus)
        muVals = vec(muVals)
        covVals = convert(Array{Float64}, thisDatCovs)

        # set up universe
        thisUniv = Univ(muVals, covVals)

        # push to list of universes
        push!(univList, thisUniv)
    end

    # put all components together
    histEnv = UnivEvol(univList, allDats, assNames)

end
