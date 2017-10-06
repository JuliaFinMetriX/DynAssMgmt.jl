# basic utilities

"""
    rawInputsToDataFrame(rawValues)

Function is basically only required to polish a slightly wrongly
read in .csv file.
"""
function rawInputsToDataFrame(rawValues)
  # process data a bit
  colnams = Array{Symbol}(rawValues[1, :])
  xxVals = Array{Float64}(rawValues[2:end, :])
  valueTab = convert(DataFrame, xxVals)
  names!(valueTab, colnams)

  # transform Matlab dates to Julia Dates
  thisDats = valueTab[:Date]
  thisDats = [Date(0000, 1, 1) + Dates.Day(convert(Int, snglDat)) for snglDat in thisDats]

  valueTab[:Date] = thisDats
  return valueTab
end

"""
    rawInputsToTimeArray(rawValues)

Function is basically only required to polish a slightly wrongly
read in .csv file.
"""
function rawInputsToTimeArray(rawValues)
  # get correct column names
  colnams = Array{Symbol}(rawValues[1, :])
  colnamsstr = [String(thisCol) for thisCol in colnams]

  xxInd = colnamsstr .== "Date"

  xxVals = Array{Float64}(rawValues[2:end, .!xxInd])

  # transform Matlab dates to Julia Dates
  thisDats = rawValues[2:end, xxInd]
  thisDats = [Date(0000, 1, 1) + Dates.Day(convert(Int, snglDat)) for snglDat in thisDats]

  return TimeArray(thisDats[:], xxVals, colnamsstr[!xxInd])
end

"""
    getNumDates(someDates)

Convert array of dates into fractional year values. This is basically
only required for plotting.
"""
function getNumDates(someDates::Array{Date, 1})
  xDates = [Dates.year(thisDat) + Dates.dayofyear(thisDat)/365 for thisDat in someDates]
end

function getShortLabels(labs::Array{Symbol, 1})
    shortLabs = String[split(String(xx), "_")[1] for xx in labs]
end

function getShortLabels(labs::Array{String, 1})
    shortLabs = String[split(xx, "_")[1] for xx in labs]
end

function symb2str(symbArr::Array{Symbol, 1})
    return convert(Array{String, 1}, symbArr)
end

function str2symb(strArr::Array{String, 1})
    return convert(Array{Symbol, 1}, strArr)
end

"""
    loadTestData(dataName::String)

Load one of the predefined test data.

## fx / Fx:

**Garch** dataset from [Ecdat R package](https://cran.r-project.org/web/packages/Ecdat/Ecdat.pdf).

Daily observations of exchange rate data from 1980–01 to 1987–05–21.
Following exchange rates are part of it:

- dm: exchange rate Dollar/Deutsch Mark
- bp: exchange rate of Dollar/British Pound
- cd: exchange rate of Dollar/Canadian Dollar
- dy: exchange rate of Dollar/Yen
- sf: exchange rate of Dollar/Swiss Franc
"""
function loadTestData(dataName::String)

    allDatasets = ["fx", "Fx"]

    if !(dataName in allDatasets)
        error("Test data with name $dataName does not exist. Allowed datasets are $allDatasets")
    end

    testData = []
    if dataName == "fx"
        testData = loadTestData_fx()
    elseif dataName == "Fx"
        testData = loadTestData_fx()
    end

    return testData
end

function loadTestData_fx()
    # load exchange rate test data as TimeArray

    # load as DataFrame
    fxRates = dataset("Ecdat", "Garch")

    # fixe dates
    dats = [Date(*("19", string(thisDat)), "yyyymmdd") for thisDat in fxRates[:Date]]
    fxRates[:Date] = dats

    # remove unrequired columns
    fxRates = fxRates[:, [:Date, :DM, :BP, :CD, :DY, :SF]]

    # convert to TimeArray
    fxTimeArray = TimeArray(fxRates, timestamp_column=:Date)

end


## basic imputation functions
"""
    locf!(xx::Array{Float64, 1})

Replacing `NaN` according to *last observation carried forward*.
"""
function locf!(xx::Array{Float64, 1})
    nObs = size(xx, 1)
    for ii=2:nObs
        if isnan(xx[ii])
            xx[ii] = xx[ii-1]
        end
    end
    return xx
end

"""
    locf(xx::Array{Float64, 1})

Replacing `NaN` according to *last observation carried forward*.
"""
function locf(xx::Array{Float64, 1})
    imputedVals = copy(xx)
    return locf!(imputedVals)
end

"""
    locf(xx::Array{Float64, 2})
"""
function locf(xx::Array{Float64, 2})
    ncols = size(xx, 2)
    for ii=1:ncols
        xx[:, ii] = locf(xx[:, ii])
    end
    return xx
end

"""
    locf(xx::TimeArray)
"""
function locf(xx::TimeSeries.TimeArray)
    # get values
    transformedValues = locf(xx.values)

    # put together TimeArray again
    xx2 = TimeSeries.TimeArray(xx.timestamp, transformedValues, xx.colnames)
end

"""
    nocb!(xx::Array{Float64, 1})

Replacing `NaN` according to *next observation carried backward*.
"""
function nocb!(xx::Array{Float64, 1})
    # next observation carried backward
    nObs = size(xx, 1)
    for ii=(nObs-1):-1:1
        if isnan(xx[ii])
            xx[ii] = xx[ii+1]
        end
    end
    return xx
end

"""
    nocb(xx::Array{Float64, 1})

Replacing `NaN` according to *next observation carried backward*.
"""
function nocb(xx::Array{Float64, 1})
    imputedVals = copy(xx)
    return nocb!(imputedVals)
end


"""
    nocb(xx::Array{Float64, 2})
"""
function nocb(xx::Array{Float64, 2})
    ncols = size(xx, 2)
    for ii=1:ncols
        xx[:, ii] = nocb(xx[:, ii])
    end
    return xx
end

"""
    nocb(xx::TimeArray)
"""
function nocb(xx::TimeSeries.TimeArray)
    # get values
    transformedValues = locf(xx.values)

    # put together TimeArray again
    xx2 = TimeSeries.TimeArray(xx.timestamp, transformedValues, xx.colnames)
end
