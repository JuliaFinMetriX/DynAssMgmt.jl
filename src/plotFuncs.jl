
# define default visualization
@recipe function f(thisUniv::Univ)
    linecolor   --> :blue
    seriestype  :=  :scatter
    title --> "Asset moments"
    legend --> false
    xaxis --> "Sigma"
    yaxis --> "Mu"
    x = sqrt.(diag(thisUniv.covs))*sqrt(52)
    y = thisUniv.mus*52
    x, y
end

@recipe function f(thisUniv::Univ, assLabs::Array{Symbol, 1})
    linecolor   --> :blue
    seriestype  :=  :scatter
    title --> "Asset moments"
    label --> hcat(assLabs...)
    xaxis --> "Sigma"
    yaxis --> "Mu"
    x = transpose(sqrt.(diag(thisUniv.covs))*sqrt(52))
    y = transpose(thisUniv.mus*52)
    x, y
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


##

function vizPf(thisUniv::Univ, pfWgts::Array{Float64, 1})
    plot(thisUniv)

    # calculate pf moments
    mu, pfVar = pfMoments(thisUniv, pfWgts)

    plot!([sqrt.(pfVar)*sqrt.(52)], [mu.*52], seriestype=:scatter)
end

function vizPf!(thisUniv::Univ, pfWgts::Array{Float64, 1})

    # calculate pf moments
    mu, pfVar = pfMoments(thisUniv, pfWgts)

    plot!([sqrt.(pfVar)*sqrt.(52)], [mu.*52], seriestype=:scatter)
end

function vizPfSpectrum(thisUniv::Univ, pfWgts::Array{Array{Float64, 1}, 1})
    plot(thisUniv)

    # calculate pf moments
    mu, pfVar = pfMoments(thisUniv, pfWgts)

    plot!([sqrt.(pfVar)*sqrt.(52)], [mu.*52], seriestype=:line)

end

function vizPfSpectrum!(thisUniv::Univ, pfWgts::Array{Array{Float64, 1}, 1})

    # calculate pf moments
    mu, pfVar = pfMoments(thisUniv, pfWgts)

    plot!([sqrt.(pfVar)*sqrt.(52)], [mu.*52], seriestype=:line)

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
