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
