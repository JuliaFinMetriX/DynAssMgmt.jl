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
