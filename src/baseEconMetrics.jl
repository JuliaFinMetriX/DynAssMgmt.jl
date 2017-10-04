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
    powVec    = [(nObs-1 : -1 : 0)...]
    wgts = persistenceVal.^powVec
    wgts = wgts ./ sum(wgts)

    # adjust observations for mean value
    meanVal = mean(data)
    zeroMeanData = data - meanVal

    ewmaStdVal = std(sum(zeroMeanData.^2 .* wgts))
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
