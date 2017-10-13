# types and functions relating to the financial environment
# - mu / sigma / covariance container
# - mu / sigma / covariance estimator

"""
    Univ(mus::Array{Float64, 1}, covs::Array{Float64, 2}, retType::ReturnType)

Universe type, built on Float64 arrays. The universe specifies
discrete asset moments: mus and covs.
"""
struct Univ
    mus::Array{Float64, 1}
    covs::Array{Float64, 2}
    retType::ReturnType
end

"""
    getUnivExtrema(thisUniv::Univ)

Get minimum and maximum values of mu and sigma for a given universe.
Helpful to determine mu / sigma targets for investment strategies.
"""
function getUnivExtrema(thisUniv::Univ)
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
    UnivEvol(manyUnivs::Array{Univ, 1}, manyDates::Array{Date, 1}, assetLabels::Array{String, 1})

Robust implementation of series of universes. In contrast to a
simple array of Univs, a UnivEvol also contains metadata like
dates and asset names.
"""
struct UnivEvol
    universes::Array{Univ, 1}
    dates::Array{Date, 1}
    assetLabels::Array{String, 1}
end

"""
    size(thisUnivEvol)

Number of dates x number of assets of universe evolution
"""
function size(thisUnivEvol::UnivEvol)
    (length(thisUnivEvol.dates), length(thisUnivEvol.assetLabels))
end

## estimator types

"""
    UnivEstimator

Abstract super type for asset moment estimators.
"""
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

function apply(thisEstimator::EWMA, rets::TimeSeries.TimeArray, retType::ReturnType)
    musHat = getEwmaMean(rets.values, thisEstimator.muPersistence)
    covsHat = getEwmaCov(rets.values, thisEstimator.covPersistence)

    return Univ(musHat[:], covsHat, retType)
end

function apply(thisEstimator::EWMA, rets::Returns)
    apply(thisEstimator, rets.data, rets.retType)
end

function applyOverTime(thisEstimator::EWMA, rets::TimeSeries.TimeArray,
    retType::ReturnType, minObs::Int)

    univList = []
    nStartInd = minObs
    nObs = size(rets.values, 1)
    for ii=nStartInd:nObs
        # apply estimator
        thisUniv = apply(thisEstimator, rets[1:ii], retType)

        # push to list of universes
        push!(univList, thisUniv)
    end

    # put all components together
    histEnv = UnivEvol(univList, rets.timestamp[nStartInd:nObs], rets.colnames)
end

function applyOverTime(thisEstimator::EWMA, rets::Returns, minObs::Int)
    applyOverTime(thisEstimator, rets.data, rets.retType, minObs)
end

## percentage scaling
"""
    getStdInPercentages(thisStd::Float64, retType::ReturnType)

Transform value of standard deviation into percentage scale if necessary.
"""
function getStdInPercentages(thisStd::Float64, retType::ReturnType)

    if retType.isPercent
        return thisStd
    else
        return thisStd * 100
    end
end

"""
    getMuInPercentages(thisMu::Float64, retType::ReturnType)

Transform value of expected return into percentage scale if necessary.
"""
function getMuInPercentages(thisMu::Float64, retType::ReturnType)

    if retType.isPercent
        return thisMu
    else
        return thisMu * 100
    end
end

"""
    getInPercentages(thisUniv::Univ)

Transform values of universe into percentage scale if necessary.
"""
function getInPercentages(thisUniv::Univ)

    retType = thisUniv.retType

    if retType.isPercent
        return thisUniv
    else
        if retType.isGross
            error("Gross returns can not be percentage returns")
        end

        newMus = thisUniv.mus * 100
        newCovs = thisUniv.covs * 100^2

        newRetType = ReturnType(true, retType.isLog, retType.period, retType.isGross)
        newUniv = Univ(newMus, newCovs, newRetType)

        return newUniv
    end
end

"""
    annualizeRiskReturn(mu::Float64, sig::Float64, retType::ReturnType)

Convert risk and return values to annual scale.
"""
function annualizeRiskReturn(mu::Float64, sig::Float64, retType::ReturnType)
    if retType.isPercent
        mu = mu / 100;
        sig = sig / 100;
    end

    if retType.isLog
        if retType.period == Base.Dates.Day(1)
            mu = mu * 252
            sig = sig * sqrt.(252)
        end
    else
        if retType.period == Base.Dates.Day(1)
            mu = mu * 252
            sig = sig * sqrt.(252)
        end
        # error("Discrete return annualization is not implemented yet.")
    end

    if retType.isPercent
        mu = mu * 100;
        sig = sig * 100;
    end

    return mu, sig
end

"""
    annualizeRiskReturn(mus::Array{Float64, 1}, sigs::Array{Float64, 1}, retType::ReturnType)

"""
function annualizeRiskReturn(mus::Array{Float64, 1}, sigs::Array{Float64, 1}, retType::ReturnType)
    # preallocation
    nVals = length(mus)

    scaledMus = zeros(Float64, nVals)
    scaledSigs = zeros(Float64, nVals)
    for ii=1:nVals
        scaledMus[ii], scaledSigs[ii] = annualizeRiskReturn(mus[ii], sigs[ii], retType)
    end

    return scaledMus, scaledSigs
end




## derive series of financial environments from matlab .csv files

"""
    getUnivEvolFromMatlabFormat(muTab::DataFrame, covsTab::DataFrame)

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
