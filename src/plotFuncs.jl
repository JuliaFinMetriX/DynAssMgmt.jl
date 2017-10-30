@recipe function f(prices::Prices; asLog=false, asNormed=false)
    # convert to desired scale
    if asNormed
        prices = normalizePrices(prices)
    end

    newPrices = []
    if asLog
        newPrices = getLogPrices(prices)
    else
        newPrices = getDiscretePrices(prices)
    end

    # get as TimeArray
    y = newPrices.data

    seriestype := :line
    y
end

@recipe function f(rets::Returns)
    y = rets.data
end

@recipe function f(perfs::Performances; asPercent=true, asLog=false, asGross=false)
    # convert to desired scale
    standPerfs = standardize(perfs)

    perfsTA = standPerfs.data
    retType = standPerfs.retType
    values = perfsTA.values

    if asLog
        values = log.(values + 1)
    end

    if asPercent
        values = values .* 100
    end

    if asGross
        values = values + 1
    end

    perfsTA = TimeArray(perfsTA.timestamp, values, perfsTA.colnames)

    # get as TimeArray
    y = perfsTA

    seriestype := :line
    y
end

@recipe function f(stratWgts::Array{PF, 1})
    # convert to matrix
    y = convert(Array{Float64, 2}, stratWgts)

    bar_width --> 0.7
    seriestype := :bar
    bar_position = :stack

    y
end

@recipe function f(thisUniv::Univ, pf::PF, doScale=true)
    # calculate pf moments
    seriestype := :scatter
    #marker --> (0.5, [:hex], 12)
    x = []
    y = []
    if doScale
        percUniv = DynAssMgmt.getInPercentages(thisUniv)
        mu, pfVola = pfMoments(percUniv, pf, "std")
        y, x = DynAssMgmt.annualizeRiskReturn([mu], [pfVola], percUniv.retType)
    else
        mu, pfVola = pfMoments(thisUniv, pf, "std")
        y, x = [mu], [pfVola]
    end
    x, y
end

@recipe function f(thisUniv::Univ, pfs::Array{PF, 1}, doScale=true)
    # calculate pf moments
    seriestype --> :scatter
    #marker --> (0.5, [:hex], 12)
    npfs = length(pfs)
    x = zeros(Float64, npfs)
    y = zeros(Float64, npfs)
    if doScale
        percUniv = DynAssMgmt.getInPercentages(thisUniv)
        for ii=1:npfs
            pf = pfs[ii]
            mu, pfVola = pfMoments(percUniv, pf, "std")
            y[ii], x[ii] = DynAssMgmt.annualizeRiskReturn(mu, pfVola, percUniv.retType)
        end
    else
        for ii=1:npfs
            pf = pfs[ii]
            y[ii], x[ii] = pfMoments(thisUniv, pf, "std")
        end
    end
    x, y
end

# define default visualization for PF types
@recipe function f(pf::PF)
    seriestype  :=  :bar
    title --> "Asset weights"
    legend --> false
    xlabel --> "Asset"
    ylabel --> "Weight"

    nAss = size(pf)
    y = pf.Wgts[:]
    y
end

@recipe function f(pf::PF, assLabs::Array{String, 1})
    seriestype  :=  :bar
    title --> "Asset weights"
    legend --> false
    xlabel --> "Asset"
    ylabel --> "Weight"

    labs = getShortLabels(assLabs)
    label --> labs
    xrotation --> 45
    legend --> true
    x = labs
    y = pf.Wgts[:]
    x, y
end

# define default visualization for Univ types
@recipe function f(thisUniv::Univ; doScale=true)
    linecolor   --> :blue
    seriestype  --> :scatter
    title --> "Asset moments"
    legend --> false
    xaxis --> "Sigma"
    yaxis --> "Mu"

    x = []
    y = []

    if doScale
        percUniv = DynAssMgmt.getInPercentages(thisUniv)
        y, x = DynAssMgmt.annualizeRiskReturn(percUniv.mus, sqrt.(diag(percUniv.covs)), percUniv.retType)
    else
        y, x = thisUniv.mus, sqrt.(diag(thisUniv.covs))
    end
    transpose(x), transpose(y)

end

@userplot PfOpts

@recipe function f(g::PfOpts; doScale=true)
    # do some calculations
    thisUniv = g.args[1]

    # compute efficient frontier
    effFrontPfs = apply(EffFront(15), thisUniv)
    effMus, effVolas = DynAssMgmt.pfMoments(thisUniv, effFrontPfs[:], "std")

    # compute diversification-aware frontier

    # equally weighted portfolio
    eqPf = apply(EqualWgts(), thisUniv)
    equWgtsMus, equWgtsSigmas = DynAssMgmt.pfMoments(thisUniv, eqPf, "std")

    x = []
    y = []

    if doScale
        percUniv = DynAssMgmt.getInPercentages(thisUniv)
        y, x = DynAssMgmt.annualizeRiskReturn(percUniv.mus, sqrt.(diag(percUniv.covs)), percUniv.retType)
    else
        y, x = thisUniv.mus, sqrt.(diag(thisUniv.covs))
    end

    legend = true
    labels := ["Assets"; "Equal weights"; "Efficient frontier";
                "Div. frontier 0.6"; "Div. frontier 0.7"; "Div. frontier 0.8";
                "Div. frontier 0.9"]

    xlabel --> "Sigma"
    ylabel --> "Mu"

    RecipesBase.@series begin
        seriestype := :scatter
        #Plots.plot(thisUniv)
        x, y
    end

    RecipesBase.@series begin
        seriestype := :scatter
        markershape := :star
        #Plots.plot(thisUniv)

        if doScale
            percUniv = DynAssMgmt.getInPercentages(thisUniv)
            y, x = DynAssMgmt.annualizeRiskReturn([equWgtsMus], [equWgtsSigmas], percUniv.retType)
        else
            y, x = ([equWgtsMus], [equWgtsSigmas])
        end
        x, y
    end

    RecipesBase.@series begin
        seriestype := :line

        if doScale
            percUniv = DynAssMgmt.getInPercentages(thisUniv)
            y, x = DynAssMgmt.annualizeRiskReturn(effMus, effVolas, percUniv.retType)
        else
            y, x = (effMus, effVolas)
        end
        #Plots.plot(thisUniv)
        x, y
    end

    sigTargets = []
    diversTarget = [0.6:0.1:0.9...]
    for thisDivTarget in diversTarget

        relDivFront = DynAssMgmt.DivFrontRelativeSigmas(thisDivTarget, 10)
        pfs = apply(relDivFront, thisUniv)

    RecipesBase.@series begin
        seriestype := :line

        y, x = pfMoments(thisUniv, pfs[:], "std")

        if doScale
            percUniv = DynAssMgmt.getInPercentages(thisUniv)
            y, x = DynAssMgmt.annualizeRiskReturn(y, x, percUniv.retType)
        end

        #Plots.plot(thisUniv)
        x, y
    end

    end

end


# define "portfolio opportunities" plot
# PlotRecipes.@userplot PfOpts

# User recipes:
# - to allow multiple dispatch:
#   - portfolio itself: bar chart
#   - portfolio with universe information: evaluate mu / sigma
# Type recipes:
# - tell the plotting engine where to find values
# - allow default settings for attributes
# -> get sigmas from universe diagonal, visualize mu/sigmas as scatter plot
# -> plot Returns by transferring request to data field (TimeSeries type)
# Plot recipes:
# - marginalhist
# Series recipes:
# - rebuild histogram from bar chart
# - apply histogram counting operation before plotting

## Desired functionality
# - mu / sigma visualizations:
#   - allow optional scaling of moments
#   - plot mus / sigmas of given universe
#   - plot mus / sigmas together with efficient frontiers
#   - plot mus / sigmas together with given portfolios

# call to plot(univ, pfs): scatter plot of asset moments, portfolios included
# call to plot(univ): simple scatter plot of asset moments
# call to plot(univ, seriestype=:pfOpts):
# - first: calculate relevant portfolios
# - then: call plot(univ, pfs)

# Desired workflow:
# - visualize universe with prominent portfolio choices, without scaling
# - add actually chosen portfolios, without scaling
# - plot!(univ, pf::PF): add single portfolio as dot
# - plot!(univ, pfs::Array{PF, 1}): add individual portfolios as dots
# - plot!(univ, pfs::Array{PF, 2}): add portfolios as line
# OR:
# - plot!(univ, pfs::Array{PF, 1}, :scatter): add individual portfolios as dots
# - plot!(univ, pfs::Array{PF, 1}, :line): add portfolios as line

# plot(univ, seriestype=:pfOpts)
# - compute prominent portfolios
# - call plot(univ)
# - call plot!(univ, PF) and plot!(univ, Array{PF, 1}) respectively


function wgtsOverTime(wgts::Array{Float64, 2}, xxDats, xxLabs; plotSettings...)

    # get cumulated weights
    stackedWgts = cumsum(wgts, 2)

    # get x-grid
    nObs, nAss = size(wgts)

    p = []

    # create a filled polygon for each item
    for ii=1:nAss
        sx = vcat(xxDats, reverse(xxDats))
        sy = vcat(stackedWgts[:,ii], ii==1 ? zeros(nObs) : reverse(stackedWgts[:,ii-1]))

        if ii==1
            p = plot(sx, sy, seriestype=:shape, label=xxLabs[ii]; plotSettings...)
        else
            plot!(sx, sy, seriestype=:shape, label=xxLabs[ii]; plotSettings...)
        end
    end

    p
end

function wgtsOverTime(someInvs::Invest, stratNum::Int; plotSettings...)
    # get PFs as normal Float64 array
    xxWgts = convert(Array{Float64, 2}, someInvs.pfs[:, stratNum])

    # get dates and labels in appropriate format
    dats = getNumDates(someInvs.dates)
    labs = getShortLabels(someInvs.assetLabels)

    # call plot function
    p = wgtsOverTime(xxWgts, dats, labs; plotSettings...)

end

function wgtsOverTime(wgts::Array{Float64, 2}; plotSettings...)

    xxDats = [ii for ii=1:size(wgts, 1)]

    # get cumulated weights
    stackedWgts = cumsum(wgts, 2)

    # get x-grid
    nObs, nAss = size(wgts)

    p = []

    # create a filled polygon for each item
    for ii=1:nAss
        sx = vcat(xxDats, reverse(xxDats))
        sy = vcat(stackedWgts[:,ii], ii==1 ? zeros(nObs) : reverse(stackedWgts[:,ii-1]))

        if ii==1
            p = plot(sx, sy, seriestype=:shape; plotSettings...)
        else
            plot!(sx, sy, seriestype=:shape; plotSettings)
        end
    end

    p
end

function tsPlot(df::DataFrame; plotSettings...)
    colNams = names(df)

    assNams = setdiff(colNams, [:Date])

    # get dates column and convert to numbers
    dats = convert(Array, df[:Date])
    dats = getNumDates(dats)

    # get values and convert to Float64
    xxVals = convert(Array, df[:, 2:end])

    p = plot(dats, xxVals; label = assNams, plotSettings...)

end

function tsPlot(ta::TimeArray; doNorm = false, plotSettings...)
    # get dates column and convert to numbers
    dats = getNumDates(ta.timestamp)

    # get values
    xxVals = ta.values

    # optionally normalize prices
    if doNorm
        xxVals = normalizePrices(xxVals)
    end

    # get labels
    assNams = ta.colnames

    p = plot(dats, xxVals; label = assNams, plotSettings...)

end
