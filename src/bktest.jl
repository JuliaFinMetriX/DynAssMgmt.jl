## define backtest functions

function evalPerf(someInvs::Invest, discRets::DataFrame)

    # get common dates
    jointDates = intersect(someInvs.dates, discRets[:Date])

    # get dimensions
    nObs = length(jointDates) - 1
    xx, nStrats, xx2 = size(someInvs)

    # preallocation
    perfs = zeros(Float64, nObs, nStrats)

    # get respective returns
    xxInds = findin(jointDates, discRets[:Date])
    perfDates = discRets[xxInds, :Date]
    associatedRets = discRets[xxInds, someInvs.assetLabels]
    associatedRets = convert(Array{Float64, 2}, associatedRets)

    # get respective weight rows
    xxIndsWgts = findin(jointDates, someInvs.dates)

    # adjust weights and returns for 1 period time lag
    associatedRets = associatedRets[2:end, :]
    perfDates = perfDates[2:end, :]
    xxIndsWgts = xxIndsWgts[1:end-1]

    # get respective weights
    for thisStratInd = 1:nStrats
        # get respective weights
        allWgts = convert(Array{Float64, 2}, someInvs.pfs[xxIndsWgts, thisStratInd])

        # calculate performances
        xxWgtRets = sum(allWgts .* associatedRets, 2)[:]
        pfVals = exp(cumsum(log(xxWgtRets./100 + 1)))

        # store performances
        perfs[:, thisStratInd] = pfVals
    end

    df1 = DataFrame(Date = perfDates[:])
    df2 = DataFrame(perfs)
    perfsDf = hcat(df1, df2)

end

# ddowns
function evalDDowns(perfDf::DataFrame)
    # get asset names without dates
    colNams = names(perfDf)
    assNams = setdiff(colNams, [:Date])

    # get values only
    perfVals = convert(Array, perfDf[:, assNams])

    ddownsVals = zeros(Float64, size(perfVals))
    for ii=1:size(perfVals, 2)
        ddownsVals[:, ii] = evalDDowns(perfVals[:, ii])
    end

    # build DataFrame again
    df1 = perfDf[:, [:Date]]
    df2 = DataFrame(ddownsVals)
    names!(df2, assNams)
    df = hcat(df1, df2)

    # get correct sorting
    ddownsDf = df[:, names(perfDf)]

end

function evalDDowns(perfVals::Array{Float64, 1})
    cumMaxPrices = cummax(perfVals)
    ddowns = 100*(perfVals ./ cumMaxPrices - 1)
end
