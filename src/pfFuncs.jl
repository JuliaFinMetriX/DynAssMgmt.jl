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

function pfDivers(wgts::Array{Float64, 1})
    # get number of assets
    nAss = size(wgts, 1)

    # get equal weights
    eqWgts = ones(Float64, nAss) ./ nAss

    # compute diversification
    1 - norm(wgts .- eqWgts)
end

function pfDivers(allWgts::Array{Float64, 2})
    # get number of assets
    nPfs, nAss = size(allWgts)

    # get equal weights
    eqWgts = ones(Float64, nAss) ./ nAss

    # compute diversification
    allDivs = zeros(Float64, nPfs)
    for ii=1:nPfs
        allDivs[ii] = pfDivers(allWgts[ii, :][:])
    end
    return allDivs

end

fullPercRet(perfVals::Array{Float64, 1}) = 100*(perfVals[end] - perfVals[1])./perfVals[1]
spMu(vals::Array{Float64, 1}) = mean(vals)
spSigma(vals::Array{Float64, 1}) = std(vals)
spVaR(vals::Array{Float64, 1}, alpha::Float64) = (-1)*quantile(vals, 1-alpha)
maxDD(perfVals::Array{Float64, 1}) = (-1)*minimum(evalDDowns(perfVals))

function dailyToAnnualMuSigmaScaling(mu, sigma)
    return naive_dailyToAnnualMuSigmaScaling(mu, sigma)
end

function naive_dailyToAnnualMuSigmaScaling(mu, sigma)
    muAnnual = mu*250
    sigmaAnnual = sigma*sqrt(250)
    return muAnnual, sigmaAnnual
end

function evalPerfStats(singlePerfVals::Array{Float64, 1})
    # get returns
    singleDiscRets = (singlePerfVals[2:end] - singlePerfVals[1:end-1])./singlePerfVals[1:end-1]

    # compute performance statistics
    perfStats = Float64[]
    statNames = Symbol[]

    # full period percentage return
    push!(perfStats, fullPercRet(singlePerfVals))
    push!(statNames, :FullPercRet)

    # single period mus
    spmuval = spMu(singleDiscRets)
    push!(perfStats, spmuval)
    push!(statNames, :SpMu)

    spsigmaval = spSigma(singleDiscRets)
    push!(perfStats, spsigmaval)
    push!(statNames, :SpSigma)

    muScaled, sigmaScaled = dailyToAnnualMuSigmaScaling(spmuval, spsigmaval)
    push!(perfStats, muScaled*100)
    push!(perfStats, sigmaScaled*100)
    push!(statNames, :MuDailyToAnnualPerc)
    push!(statNames, :SigmaDailyToAnnualPerc)

    push!(perfStats, spVaR(singleDiscRets, 0.95))
    push!(statNames, :SpVaR)

    push!(perfStats, maxDD(singlePerfVals))
    push!(statNames, :MaxDD)

    return (perfStats, statNames)
end

function evalPerfStats(singlePerfVals::Array{Float64, 1}, dats::Array{Date, 1})
    # TODO: make use of dates array

    # get statistics that do not require dates
    perfStats, statNames = evalPerfStats(singlePerfVals)
end

type PerfStats
    FullPercRet::Float64
    SpMu::Float64
    SpSigma::Float64
    MuDailyToAnnualPerc::Float64
    SigmaDailyToAnnualPerc::Float64
    SpVaR::Float64
    MaxDD::Float64
    VaR::Float64
    GeoMean::Float64
    # DateRange::Array{Date, 1}
end

PerfStats() = PerfStats(NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN)

function PerfStats(vals::Array{Float64, 1}, statNams::Array{Symbol, 1})
    # preallocate
    perfStatInstance = PerfStats()

    for ii=1:length(vals)
        setfield!(perfStatInstance, statNams[ii], vals[ii])
    end

    return perfStatInstance
end
