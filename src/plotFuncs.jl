
# define default visualization
@recipe function f(thisUniv::Univ)
    linecolor   --> :blue
    seriestype  :=  :scatter
    title --> "Asset moments"
    legend --> false
    xaxis --> "Sigma"
    yaxis --> "Mu"

    percUniv = DynAssMgmt.getInPercentages(thisUniv)
    y, x = DynAssMgmt.annualizeRiskReturn(percUniv.mus, sqrt.(diag(percUniv.covs)), percUniv.retType)
    transpose(x), transpose(y)
end

@recipe function f(thisUniv::Univ, assLabs::Array{Symbol, 1})
    linecolor   --> :blue
    seriestype  :=  :scatter
    title --> "Asset moments"
    label --> hcat(assLabs...)
    xaxis --> "Sigma"
    yaxis --> "Mu"

    percUniv = DynAssMgmt.getInPercentages(thisUniv)
    y, x = DynAssMgmt.annualizeRiskReturn(percUniv.mus, sqrt.(diag(percUniv.covs)), percUniv.retType)
    transpose(x), transpose(y)
end

@recipe function f(thisUniv::Univ, assLabs::Array{String, 1})
    linecolor   --> :blue
    seriestype  :=  :scatter
    title --> "Asset moments"
    label --> hcat(assLabs...)
    xaxis --> "Sigma"
    yaxis --> "Mu"

    percUniv = DynAssMgmt.getInPercentages(thisUniv)
    y, x = DynAssMgmt.annualizeRiskReturn(percUniv.mus, sqrt.(diag(percUniv.covs)), percUniv.retType)
    transpose(x), transpose(y)
end


# define default visualization for PF types
@recipe function f(pf::PF)
    seriestype  :=  :bar
    title --> "Asset weights"
    legend --> false
    xaxis --> "Asset"
    yaxis --> "Weight"

    nAss = size(pf)
    x = [1:nAss][:]
    y = pf.Wgts[:]
    x, y
end

@recipe function f(pf::PF, assLabs::Array{Symbol, 1})
    seriestype  :=  :bar
    title --> "Asset weights"
    legend --> false
    xaxis --> "Asset"
    yaxis --> "Weight"
    labs = getShortLabels(assLabs)
    label --> labs
    rotation --> 45

    x = labs[:]
    y = pf.Wgts[:]
    x, y
end

@recipe function f(pf::PF, assLabs::Array{String, 1})
    seriestype  :=  :bar
    title --> "Asset weights"
    legend --> false
    xaxis --> "Asset"
    yaxis --> "Weight"
    labs = getShortLabels(assLabs)
    label --> labs
    rotation --> 45

    x = labs[:]
    y = pf.Wgts[:]
    x, y
end


##
function vizPf!(thisUniv::Univ, pfWgts::Array{Float64, 1})
    # calculate pf moments
    percUniv = DynAssMgmt.getInPercentages(thisUniv)
    mu, pfVola = pfMoments(percUniv, pfWgts, "std")
    mu, pfVola = DynAssMgmt.annualizeRiskReturn(mu, pfVola, percUniv.retType)

    plot!([pfVola], [mu], seriestype=:scatter, m=(0.5, [:hex], 12))
end

function vizPf!(thisUniv::Univ, pf::PF)
    vizPf!(thisUniv, pf.Wgts)
end

function vizPf(thisUniv::Univ, pfWgts::Array{Float64, 1})
    plot(thisUniv)

    vizPf!(thisUniv, pfWgts)
end

function vizPf(thisUniv::Univ, pf::PF)
    vizPf(thisUniv, pf.Wgts)
end

function vizPfSpectrum(thisUniv::Univ, pfWgts::Array{PF, 1})
    plot(thisUniv)

    # calculate pf moments
    percUniv = DynAssMgmt.getInPercentages(thisUniv)
    mu, pfVola = pfMoments(percUniv, pfWgts, "std")
    mu, pfVola = DynAssMgmt.annualizeRiskReturn(mu, pfVola, percUniv.retType)

    plot!([pfVola], [mu], seriestype=:line)

end

function vizPfSpectrum!(thisUniv::Univ, pfWgts::Array{PF, 1})

    # calculate pf moments
    percUniv = DynAssMgmt.getInPercentages(thisUniv)
    mu, pfVola = pfMoments(percUniv, pfWgts, "std")
    mu, pfVola = DynAssMgmt.annualizeRiskReturn(mu, pfVola, percUniv.retType)

    plot!([pfVola], [mu], seriestype=:line)

end

function wgtsOverTime(wgts::Array{Float64, 2}, xxDats, xxLabs)

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
        p = plot(sx, sy, seriestype=:shape, label=xxLabs[ii])
    else
        plot!(sx, sy, seriestype=:shape, label=xxLabs[ii])
    end
end

p
end

function wgtsOverTime(someInvs::Invest, stratNum::Int)
    # get PFs as normal Float64 array
    xxWgts = convert(Array{Float64, 2}, someInvs.pfs[:, stratNum])

    # get dates and labels in appropriate format
    dats = getNumDates(someInvs.dates)
    labs = getShortLabels(someInvs.assetLabels)

    # call plot function
    p = wgtsOverTime(xxWgts, dats, labs)

end

function wgtsOverTime(wgts::Array{Float64, 2})

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
        p = plot(sx, sy, seriestype=:shape)
    else
        plot!(sx, sy, seriestype=:shape)
    end
end

p
end

function wgtsOverStrategies(stratWgts::Array{PF, 2})

    xxWgts = convert(Array{Float64, 2}, stratWgts[:])

    p = groupedbar(xxWgts, bar_position = :stack, bar_width=0.7)

    p
end

function wgtsOverStrategies(stratWgts::Array{PF, 2}, assLabs::Array{Symbol, 1})
    labs = getShortLabels(assLabs)
    xxWgts = convert(Array{Float64, 2}, stratWgts[:])

    p = groupedbar(xxWgts, bar_position = :stack, bar_width=0.7, label = hcat(labs...))

    p
end

function tsPlot(df::DataFrame)
    colNams = names(df)

    assNams = setdiff(colNams, [:Date])

    # get dates column and convert to numbers
    dats = convert(Array, df[:Date])
    dats = getNumDates(dats)

    # get values and convert to Float64
    xxVals = convert(Array, df[:, 2:end])

    p = plot(dats, xxVals; label = assNams)

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
