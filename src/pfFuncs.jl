# portfolio moments

## evaluate portfolio for universe / universe evolution
function pfVariance(covs::Array{Float64, 2}, wgts::Array{Float64, 1})
    wgts'*covs*wgts
end

function pfMu(mus::Array{Float64, 1}, wgts::Array{Float64, 1})
    wgts'mus
end

function pfMoments(mus::Array{Float64, 1}, covs::Array{Float64, 2}, wgts::Array{Float64, 1})
    pfMu(mus, wgts), pfVariance(covs, wgts)
end

function pfMoments(thisUniv::Univ, wgts::Array{Float64, 1})
    pfMoments(thisUniv.mus, thisUniv.covs, wgts)
end

function pfMoments(univHist::UnivEvol, wgts::Array{Float64, 1})
    # preallocation
    nObs, nAss = size(univHist)
    allMoments = zeros(nObs, 2)

    for ii=1:nObs
        thisMu, thisVariance = pfMoments(univHist.universes[ii], wgts)
        allMoments[ii, :] = [thisMu thisVariance]
    end
    mus = allMoments[:, 1]
    vars = allMoments[:, 2]
    return mus, vars
end

function pfMoments(univHist::Univ, pfWgts::Array{Array{Float64, 1}, 1})
    # get dimensions
    nObs = size(pfWgts, 1)

    pfMus, pfVars = (zeros(Float64, nObs), zeros(Float64, nObs))

    for ii=1:nObs
        pfMus[ii], pfVars[ii] = pfMoments(univHist, pfWgts[ii][:])
    end
    return pfMus, pfVars
end

function pfMoments(univHist::Univ, wgts::Array{Float64, 2})
    # get dimensions
    nObs, nAss = size(wgts)

    pfMus, pfVars = (zeros(Float64, nObs), zeros(Float64, nObs))

    for ii=1:nObs
        pfMus[ii], pfVars[ii] = pfMoments(univHist, wgts[ii, :][:])
    end
    return pfMus, pfVars
end

function pfMoments(univHist::UnivEvol, wgts::Array{Float64, 2})

    # get dimensions
    nObs = size(univHist, 1)
    nObs2 = size(wgts, 1)

    if nObs != nObs2
        error("Number of different days must match")
    end

    dailyPfMus = zeros(Float64, nObs)
    dailyPfVars = zeros(Float64, nObs)
    for ii=1:nObs
        thisUniv = univHistory.universes[ii]

        thisWgts = wgts[ii, :]
        mu, pfvar = pfMoments(thisUniv, thisWgts[:])

        dailyPfMus[ii] = mu
        dailyPfVars[ii] = pfvar
    end
    return dailyPfMus, dailyPfVars

end
