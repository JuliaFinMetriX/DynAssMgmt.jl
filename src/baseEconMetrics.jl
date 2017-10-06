## econometrics functions
# - sampleStd (regular, exp. weighted)
# - sampleMean (regular, exp. weighted)
# - price2ret

"""
    getEwmaStd(data::Array{Float64, 1}, persistenceVal::Float64)

EWMA estimator of standard deviation. `persistenceVal` defines how
much weight historic observations get, and hence implicitly also
defines the weight of the most recent observation.
"""
function getEwmaStd(data::Array{Float64, 1}, persistenceVal::Float64)
    nObs = length(data)

    # get observation weights
    powVec = [(nObs-1 : -1 : 0)...]
    wgts = persistenceVal.^powVec
    wgts = wgts ./ sum(wgts)

    # adjust observations for mean value
    meanVal = mean(data)
    zeroMeanData = data - meanVal

    ewmaStdVal = sqrt(sum(zeroMeanData.^2 .* wgts))
end

"""
    getEwmaStd(data::Array{Float64, 2}, persistenceVal::Float64)
"""
function getEwmaStd(data::Array{Float64, 2}, persistenceVal::Float64)
    ncols = size(data, 2)

    ewmaStdVals = zeros(Float64, 1, ncols)

    for ii=1:ncols
        ewmaStdVals[ii] = getEwmaStd(data[:, ii], persistenceVal)
    end
    return ewmaStdVals
end

"""
    getEwmaStd(data::TimeArray, persistenceVal::Float64)
"""
function getEwmaStd(data::TimeArray, persistenceVal::Float64)
    return getEwmaStd(data.values, persistenceVal)
end

"""
    getEwmaMean(data::Array{Float64, 1}, persistenceVal::Float64)

EWMA estimator of expected value. `persistenceVal` defines how
much weight historic observations get, and hence implicitly also
defines the weight of the most recent observation.
"""
function getEwmaMean(data::Array{Float64, 1}, persistenceVal::Float64)
    nObs = length(data)

    # get observation weights
    powVec = [(nObs-1 : -1 : 0)...]
    wgts = persistenceVal.^powVec
    wgts = wgts ./ sum(wgts)

    ewmaVal = sum(data .* wgts)
end

"""
    getEwmaMean(data::Array{Float64, 2}, persistenceVal::Float64)
"""
function getEwmaMean(data::Array{Float64, 2}, persistenceVal::Float64)
    ncols = size(data, 2)

    ewmaVals = zeros(Float64, 1, ncols)

    for ii=1:ncols
        ewmaVals[ii] = getEwmaMean(data[:, ii], persistenceVal)
    end
    return ewmaVals
end

"""
    getEwmaMean(data::TimeArray, persistenceVal::Float64)
"""
function getEwmaMean(data::TimeArray, persistenceVal::Float64)
    return getEwmaMean(data.values, persistenceVal)
end




"""
    getEwmaCov(data::Array{Float64, 1}, persistenceVal::Float64)

EWMA estimator of covariance matrix. `persistenceVal` defines how
much weight historic observations get, and hence implicitly also
defines the weight of the most recent observation.
"""
function getEwmaCov(data::Array{Float64, 2}, persistenceVal::Float64)
    nObs, nAss = size(data)

    # get observation weights
    powVec = [(nObs-1 : -1 : 0)...]
    wgts = persistenceVal.^powVec
    wgts = wgts ./ sum(wgts)

    # adjust observations for mean value
    meanVal = mean(data, 1)
    zeroMeanData = data - repmat(meanVal, nObs, 1)

    # compute EWMA covariance matrix
    covMatr = zeroMeanData' * (zeroMeanData .* repmat(wgts, 1, nAss))

    # enforce numerical symmetry
    covMatr = 0.5 * (covMatr + covMatr')

end

"""
    getEwmaCov(data::TimeArray, persistenceVal::Float64)
"""
function getEwmaCov(data::TimeArray, persistenceVal::Float64)
    return getEwmaCov(data.values, persistenceVal)
end
