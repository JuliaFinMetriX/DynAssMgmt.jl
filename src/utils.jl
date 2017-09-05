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
