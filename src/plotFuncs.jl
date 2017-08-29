
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
