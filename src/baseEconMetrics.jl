## econometrics functions
# - sampleStd (regular, exp. weighted)
# - sampleMean (regular, exp. weighted)
# - price2ret

"""
    computeReturns(prices::Array{Float64, 1})

Compute returns from prices. The function uses default settings
for return calculations:

- discrete returns (not logarithmic)
- fractional returns (not percentage)
- single-period returns (not multi-period)
- net returns (not gross returns)
- straight-forward application to `NaN`s also

"""
function computeReturns(prices::Array{Float64, 1})
    return (prices[2:end] - prices[1:end-1]) ./ prices[1:end-1]
end

"""
    computeReturns(prices::Array{Float64, 2})
"""
function computeReturns(prices::Array{Float64, 2})
    nObs, ncols = size(data)

    discRets = zeros(Float64, nObs-1, ncols)

    for ii=1:ncols
        discRets[:, ii] = computeReturns(prices[:, ii])
    end
    return discRets
end


"""
    computeReturns(xx::TimeSeries.TimeArray)
"""
function computeReturns(xx::TimeSeries.TimeArray)
    # get values
    discRets = computeReturns(xx.values)

    # put together TimeArray again
    xx = TimeSeries.TimeArray(xx.timestamp[2:end], discRets, xx.colnames)
end


"""
    rets2prices(discRets::Array{Float64, 1}, startPrice=1., prependStart=false)

Aggregate returns to prices (not performances). The function uses default types
of returns:

- discrete returns (not logarithmic)
- fractional returns (not percentage)
- single-period returns (not multi-period)
- net returns (not gross returns)
- convention for how to deal with `NaN`s still needs to be defined

"""
function rets2prices(discRets::Array{Float64, 1}, startPrice=1., prependStart=false)
    # transform to log returns
    logRets = log.(1 + discRets)

    # aggregate in log world
    logPerf = cumsum(logRets) + log.(startPrice)

    # transform back to discrete world
    prices = exp.(logPerf)

    if prependStart
        prices = [startPrice; prices]
    end

    return prices
end

"""
    rets2prices(discRets::Array{Float64, 2})
"""
function rets2prices(discRets::Array{Float64, 2}, startPrice=1., prependStart=false)
    nObs, ncols = size(discRets)

    if prependStart
        prices = zeros(Float64, nObs, ncols)
    else
        prices = zeros(Float64, nObs-1, ncols)
    end

    for ii=1:ncols
        prices[:, ii] = rets2prices(discRets[:, ii], startPrice, prependStart)
    end

    return prices
end


"""
    rets2prices(discRets::TimeSeries.TimeArray, startPrice=1., prependStart=false)
"""
function rets2prices(discRets::TimeSeries.TimeArray, startPrice=1., prependStart=false)
    # get values
    prices = rets2prices(discRets.values, startPrice, prependStart)

    if prependStart
        dats = [discRets.timestamp[1] - Dates.Day(1); discRets.timestamp]
        prices = TimeSeries.TimeArray(dats, prices, discRets.colnames)
    else
        prices = TimeSeries.TimeArray(discRets.timestamp, prices, discRets.colnames)
    end

    return prices
end


## aggregate returns
"""
    aggregateReturns(rets::Array{Float64, 1})

Aggregate returns to performances (not prices). The function uses default types
of returns:

- discrete returns (not logarithmic)
- fractional returns (not percentage)
- single-period returns (not multi-period)
- net returns (not gross returns)
- convention for how to deal with `NaN`s still needs to be defined

"""
function aggregateReturns(discRets::Array{Float64, 1}, prependStart=false)
    prices = rets2prices(discRets, 1.0, prependStart)
    perfVals = prices - 1
end


"""
    aggregateReturns(discRets::Array{Float64, 2}, prependStart=false)

"""
function aggregateReturns(discRets::Array{Float64, 2}, prependStart=false)
    prices = rets2prices(discRets, 1.0, prependStart)
    perfVals = prices - 1
end

"""
    aggregateReturns(discRets::TimeSeries.TimeArray, prependStart=false)

"""
function aggregateReturns(discRets::TimeSeries.TimeArray, prependStart=false)
    prices = rets2prices(discRets, 1.0, prependStart)
    prices.values = prices.values - 1
    return prices
end


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
