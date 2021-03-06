## data types
# Returns
# Perform
# - nothing else than aggregated returns
# - should also be built around ReturnType
# Prices
# - could be log / discrete prices

## econometrics functions
# - sampleStd (regular, exp. weighted)
# - sampleMean (regular, exp. weighted)
# - price2ret

"""
    ReturnType(isPercent::Bool, isLog::Bool, period::Dates.DatePeriod, isGross::Bool)

Specification of return type. Returns could differ with regards
to following properties:

- fractional / percentage returns
- discrete / logarithmic returns
- daily, monthly, yearly, ... returns
- net / gross returns

Standard return type is *fractional*, *discrete*, *net* daily returns.
"""
struct ReturnType
    isPercent::Bool
    isLog::Bool
    period::Base.Dates.DatePeriod
    isGross::Bool

    function ReturnType(isPercent, isLog, somePeriod, isGross)
        if isLog & isGross
            error("Logarithmic returns can not be gross returns")
        end

        if isPercent & isGross
            error("Gross returns can not be percentage returns")
        end

        return new(isPercent, isLog, somePeriod, isGross)
    end
end

ReturnType() = ReturnType(false, false, Dates.Day(1), false)

"""
    Returns(data::TimeSeries.TimeArray, retType::ReturnType)

Data type to store return data together with meta-data.
"""
struct Returns
    data::TimeSeries.TimeArray
    retType::ReturnType
end

"""
    standardize(rets::Returns)

Convert return data to default return type:
*fractional*, *discrete* and *net* returns.
"""
function standardize(rets::Returns)
    retsTA = rets.data
    retType = rets.retType
    values = retsTA.values
    if retType.isGross
        values = values - 1
    end

    if retType.isPercent
        values = values / 100
    end

    if retType.isLog
        values = exp(values) - 1
    end

    retsTA = TimeArray(retsTA.timestamp, values, retsTA.colnames)

    standRetType = ReturnType(false, false, retType.period, false)
    standRets = Returns(retsTA, standRetType)

end

"""
    Prices(data::TimeSeries.TimeArray, isLog::Bool)

Data type to store prices together with meta-data. This basically allows
to robustly identify logarithmic prices.
"""
struct Prices
    data::TimeSeries.TimeArray
    isLog::Bool
end

Prices() = Prices(data::TimeSeries.TimeArray, false)

"""
    standardize(prices::Prices)

Convert price data to default price type: discrete, not logarithmic prices.
"""
function standardize(prices::Prices)
    if prices.isLog
        prices = getDiscretePrices(prices)
    end
    return prices
end

"""
    getLogPrices(prices::Prices)

Transform prices to logarithmic prices if necessary.
"""
function getLogPrices(prices::Prices)
    if prices.isLog
        return prices
    else
        priceData = prices.data
        logData = TimeSeries.TimeArray(priceData.timestamp, log.(priceData.values), priceData.colnames)
        return Prices(logData, true)
    end
end

"""
    getDiscretePrices(prices::Prices)

Transform prices to discrete values if necessary.
"""
function getDiscretePrices(prices::Prices)
    if prices.isLog
        priceData = prices.data
        logData = TimeSeries.TimeArray(priceData.timestamp, exp.(priceData.values), priceData.colnames)
        return Prices(logData, true)
    else
        return prices
    end
end

## normalize prices

"""
    normalizePrices(xx::Array{Float64, 1})

Rescale prices such that first observation starts at 1.
"""
function normalizePrices(prices::Array{Float64, 1})
    nObs = size(prices, 1)

    # make sure that first observation is not NaN
    imputedPrices = DynAssMgmt.nocb(DynAssMgmt.locf(prices))

    repeatedInitVals = imputedPrices[1] .* ones(Float64, nObs)
    normedValues = prices ./ repeatedInitVals
end

"""
    normalizePrices(xx::Array{Float64, 2})
"""
function normalizePrices(prices::Array{Float64, 2})
    nrows, ncols = size(prices)
    normedValues = copy(prices)
    for ii=1:ncols
        normedValues[:, ii] = normalizePrices(prices[:, ii])
    end
    return normedValues
end

"""
    normalizePrices(xx::TimeArray)
"""
function normalizePrices(prices::TimeSeries.TimeArray)
    # get normalized values
    normedPrices = normalizePrices(prices.values)

    # put together TimeArray again
    normedPrices = TimeSeries.TimeArray(prices.timestamp, normedPrices, prices.colnames)
end

"""
    normalizePrices(xx::Prices)
"""
function normalizePrices(prices::Prices)
    # get standard format for prices
    standPrices = standardize(prices)

    # get normalized values
    normedPrices = normalizePrices(standPrices.data)

    # put together TimeArray again
    normedPrices = Prices(normedPrices, false)
end

"""
    Performance(data::TimeSeries.TimeArray, retType::ReturnType)

Data type to store performance data together with meta-data. Performance
basically can be interpreted as aggregated returns. For the special case of
gross performance values, performances also can be interpreted as normalized
prices.
"""
struct Performances
    data::TimeSeries.TimeArray
    retType::ReturnType
end

"""
    standardize(perfs::Performances)

Convert performance data to default performance type:
*fractional*, *discrete* and *net* performances.
"""
function standardize(perfs::Performances)
    perfsTA = perfs.data
    retType = perfs.retType
    values = perfsTA.values
    if retType.isGross
        values = values - 1
    end

    if retType.isPercent
        values = values / 100
    end

    if retType.isLog
        values = exp(values) - 1
    end

    perfsTA = TimeArray(perfsTA.timestamp, values, perfsTA.colnames)

    standRetType = ReturnType(false, false, retType.period, false)
    standPerfs = Performances(perfsTA, standRetType)

end

function getGrossPerformances(perfs::Performances)
    retType = perfs.retType
    if retType.isGross
        return perfs
    end

    standPerfs = standardize(perfs)
    values = standPerfs.data.values

    # make gross returns
    values = values + 1

    perfsTA = TimeArray(standPerfs.data.timestamp, values, standPerfs.data.colnames)
    newRetType = ReturnType(false, false, retType.period, true)
    return Performances(perfsTA, newRetType)
end

"""
    computeReturns(prices::Array{Float64, 1}, retType = ReturnType())

Compute returns from prices. The function uses default settings
for return calculations:

- discrete returns (not logarithmic)
- fractional returns (not percentage)
- single-period returns (not multi-period)
- net returns (not gross returns)
- straight-forward application to `NaN`s also

"""
function computeReturns(prices::Array{Float64, 1}, retType = ReturnType())

    # get discrete net returns
    rets = (prices[2:end] - prices[1:end-1]) ./ prices[1:end-1]

    if retType.isLog
        rets = log.(rets + 1)
    end

    if retType.isPercent
        rets = rets * 100
    end

    if retType.isGross
        rets = rets + 1
    end

    # hand back Returns type
    return rets
end

"""
    computeReturns(prices::Array{Float64, 2}, retType = ReturnType())
"""
function computeReturns(prices::Array{Float64, 2}, retType = ReturnType())
    nObs, ncols = size(prices)

    rets = zeros(Float64, nObs-1, ncols)

    for ii=1:ncols
        rets[:, ii] = computeReturns(prices[:, ii], retType)
    end
    return rets
end


"""
    computeReturns(xx::TimeSeries.TimeArray, retType = ReturnType())
"""
function computeReturns(xx::TimeSeries.TimeArray, retType = ReturnType())
    # get values
    rets = computeReturns(xx.values, retType)

    # put together TimeArray again
    xx = TimeSeries.TimeArray(xx.timestamp[2:end], rets, xx.colnames)

    # create Returns type
    return Returns(xx, retType)
end


"""
    rets2prices(rets::Array{Float64, 1}, retType::ReturnType, startPrice=1., prependStart=false)

Aggregate returns to prices (not performances). The function uses default types
of returns:

- discrete returns (not logarithmic)
- fractional returns (not percentage)
- single-period returns (not multi-period)
- net returns (not gross returns)
- convention for how to deal with `NaN`s still needs to be defined

"""
function rets2prices(rets::Array{Float64, 1}, retType::ReturnType, startPrice=1., prependStart=false)

    if retType.isGross
        rets = rets - 1
    end

    if retType.isPercent
        rets = rets ./ 100
    end

    if !retType.isLog
        # transform to log returns
        logRets = log.(1 + rets)
    end

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
    rets2prices(rets::Array{Float64, 2}, retType::ReturnType)
"""
function rets2prices(rets::Array{Float64, 2}, retType::ReturnType, startPrice=1., prependStart=false)
    nObs, ncols = size(rets)

    if prependStart
        prices = zeros(Float64, nObs+1, ncols)
    else
        prices = zeros(Float64, nObs, ncols)
    end

    for ii=1:ncols
        prices[:, ii] = rets2prices(rets[:, ii], retType, startPrice, prependStart)
    end

    return prices
end


"""
    rets2prices(rets::TimeSeries.TimeArray, retType::ReturnType, startPrice=1., prependStart=false)
"""
function rets2prices(rets::TimeSeries.TimeArray, retType::ReturnType, startPrice=1., prependStart=false)
    # get values
    prices = rets2prices(rets.values, retType, startPrice, prependStart)

    if prependStart
        dats = [rets.timestamp[1] - Dates.Day(1); rets.timestamp]
        prices = TimeSeries.TimeArray(dats, prices, rets.colnames)
    else
        prices = TimeSeries.TimeArray(rets.timestamp, prices, rets.colnames)
    end

    return prices
end

"""
    rets2prices(rets::Returns, startPrice=1., prependStart=false)
"""
function rets2prices(rets::Returns, startPrice=1., prependStart=false)
    # get values
    prices = rets2prices(rets.data, rets.retType, startPrice, prependStart)

    # get as high-level data type
    return Prices(prices, false)
end


## aggregate returns
"""
    aggregateReturns(rets::Array{Float64, 1}, retType::ReturnType, prependStart=false)

Aggregate returns to performances (not prices). The function uses default types
of returns:

- discrete returns (not logarithmic)
- fractional returns (not percentage)
- single-period returns (not multi-period)
- net returns (not gross returns)
- convention for how to deal with `NaN`s still needs to be defined

"""
function aggregateReturns(discRets::Array{Float64, 1}, retType::ReturnType, prependStart=false)
    prices = rets2prices(discRets, retType, 1.0, prependStart)
    perfVals = prices - 1
end


"""
    aggregateReturns(discRets::Array{Float64, 2}, retType::ReturnType, prependStart=false)

"""
function aggregateReturns(discRets::Array{Float64, 2}, retType::ReturnType, prependStart=false)
    prices = rets2prices(discRets, retType, 1.0, prependStart)
    perfVals = prices - 1
end

"""
    aggregateReturns(discRets::TimeSeries.TimeArray, retType::ReturnType, prependStart=false)

"""
function aggregateReturns(discRets::TimeSeries.TimeArray, retType::ReturnType, prependStart=false)
    prices = rets2prices(discRets, retType, 1.0, prependStart)
    newValues = prices.values - 1
	 return TimeSeries.TimeArray(prices.timestamp, newValues, prices.colnames)
end

"""
    aggregateReturns(rets::Returns, prependStart=false)

"""
function aggregateReturns(rets::Returns, prependStart=false)
    prices = rets2prices(rets.data, rets.retType, 1.0, prependStart)
    newValues = prices.values - 1

    data = TimeSeries.TimeArray(prices.timestamp, newValues, prices.colnames)

    return Performances(data, ReturnType())
end

## define default conversion methods between Prices, Returns and Performances
import Base.convert
function convert(::Type{Returns}, prices::Prices)
    # get prices in standardized format
    standPrices = standardize(prices)

    # compute returns
    rets = computeReturns(standPrices.data, ReturnType())

end

function convert(::Type{Performances}, prices::Prices)
    # get prices in standardized format
    standPrices = standardize(prices)

    # transform values
    vals = standPrices.data.values
    nObs, nAss = size(vals)
    initVals = reshape(vals[1, :], 1, nAss)
    perfVals = vals ./ repmat(initVals, nObs, 1) - 1

    # attach meta-data again
    perfTa = TimeSeries.TimeArray(prices.data.timestamp, perfVals, prices.data.colnames)
    perfs = Performances(perfTa, ReturnType())
end

function convert(::Type{Performances}, rets::Returns)
    # standardize returns
    perfs = aggregateReturns(rets, true)
end

function convert(::Type{Prices}, perfs::Performances)
    grossPerfs = getGrossPerformances(perfs)
    return Prices(grossPerfs.data, false)
end

function convert(::Type{Prices}, rets::Returns)
    prices = rets2prices(rets, 1., true)
end

function convert(::Type{Returns}, perfs::Performances)
    synthPrices = convert(Prices, perfs)
    return convert(Returns, synthPrices)
end

## define EWMA estimators

function ewmaObsWgtPower(nObs::Int)
    return Int[ii for ii=nObs-1:-1:0]
end

function ewmaObsWgts(obsPowers::Array{Int, 1}, persistenceVal::Float64)
    wgts = persistenceVal.^obsPowers
    obsWgts = wgts ./ sum(wgts)
    return obsWgts
end

function cutoffOldData(data::Array{Float64, 2}, nCutoff::Int)
    nObs = size(data, 1)

    if nObs > nCutoff
        data = data[(end-nCutoff+1):end, :]
    end
    return data
end

function cutoffOldData(data::Array{Float64, 1}, nCutoff::Int)
    nObs = length(data)

    if nObs > nCutoff
        data = data[(end-nCutoff+1):end]
    end
    return data
end


"""
    getEwmaStd(data::Array{Float64, 1}, persistenceVal::Float64)

EWMA estimator of standard deviation. `persistenceVal` defines how
much weight historic observations get, and hence implicitly also
defines the weight of the most recent observation.
"""
function getEwmaStd(data::Array{Float64, 1}, persistenceVal::Float64)

    data = DynAssMgmt.cutoffOldData(data, 2000)

    nObs = length(data)

    # get observation weights
    obsPowers = ewmaObsWgtPower(nObs)
    wgts = ewmaObsWgts(obsPowers, persistenceVal)

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
    getEwmaStd(data::Returns, persistenceVal::Float64)
"""
function getEwmaStd(data::Returns, persistenceVal::Float64)
    return getEwmaStd(data.data, persistenceVal)
end

"""
    getEwmaMean(data::Array{Float64, 1}, persistenceVal::Float64)

EWMA estimator of expected value. `persistenceVal` defines how
much weight historic observations get, and hence implicitly also
defines the weight of the most recent observation.
"""
function getEwmaMean(data::Array{Float64, 1}, persistenceVal::Float64)

    data = DynAssMgmt.cutoffOldData(data, 2000)

    nObs = length(data)

    # get observation weights
    obsPowers = ewmaObsWgtPower(nObs)
    wgts = ewmaObsWgts(obsPowers, persistenceVal)

    ewmaVal = sum(data .* wgts)
end

"""
    getEwmaMean(data::Array{Float64, 2}, persistenceVal::Float64)
"""
function getEwmaMean(data::Array{Float64, 2}, persistenceVal::Float64)

    data = DynAssMgmt.cutoffOldData(data, 2000)

    nObs, ncols = size(data)

    ewmaVals = zeros(Float64, 1, ncols)

    # get observation weights
    obsPowers = ewmaObsWgtPower(nObs)
    wgts = ewmaObsWgts(obsPowers, persistenceVal)

    wgtedObs = data .* repmat(wgts, 1, ncols)

    return sum(wgtedObs, 1)
end

"""
    getEwmaMean(data::TimeArray, persistenceVal::Float64)
"""
function getEwmaMean(data::TimeArray, persistenceVal::Float64)
    return getEwmaMean(data.values, persistenceVal)
end

"""
    getEwmaMean(data::Returns, persistenceVal::Float64)
"""
function getEwmaMean(data::Returns, persistenceVal::Float64)
    return getEwmaMean(data.data, persistenceVal)
end

function isPosSemiDef(A::Array{Float64, 2})
    V = eigvals(Symmetric(full(A)))

    if !all(V .>= 0) & !all(V .<= 0)
        return false
    else
        return true
    end
end


"""
    getEwmaCov(data::Array{Float64, 1}, persistenceVal::Float64)

EWMA estimator of covariance matrix. `persistenceVal` defines how
much weight historic observations get, and hence implicitly also
defines the weight of the most recent observation.
"""
function getEwmaCov(data::Array{Float64, 2}, persistenceVal::Float64)
    data = DynAssMgmt.cutoffOldData(data, 2000)

    nObs, nAss = size(data)

    # get observation weights
    obsPowers = ewmaObsWgtPower(nObs)
    wgts = ewmaObsWgts(obsPowers, persistenceVal)

    # adjust observations for mean value
    meanVal = mean(data, 1)
    zeroMeanData = data - repmat(meanVal, nObs, 1)

    # compute EWMA covariance matrix
    covMatr = zeroMeanData' * (zeroMeanData .* repmat(wgts, 1, nAss))

    # enforce numerical symmetry
    covMatr = 0.5 * (covMatr + covMatr')

    # check positive semidefinite-ness
    if !DynAssMgmt.isPosSemiDef(covMatr)
        error("Covariance matrix is not positive semidefinite")
    end

    return covMatr

end


"""
    getEwmaCov(data::TimeArray, persistenceVal::Float64)
"""
function getEwmaCov(data::TimeArray, persistenceVal::Float64)
    return getEwmaCov(data.values, persistenceVal)
end

"""
    getEwmaCov(data::Returns, persistenceVal::Float64)
"""
function getEwmaCov(data::Returns, persistenceVal::Float64)
    return getEwmaCov(data.data, persistenceVal)
end
