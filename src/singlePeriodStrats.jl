## single-period portfolio strategies

# TODO: define strategy type
# then we could do: solve!(thisUniv, thisStrat)
# visualize universe
# allow array of universes
# visualize portfolio for given universe

# get global minimum variance portfolio
"""
    gmvp_lev(thisUniv)

Get global minimum variance portfolio without any constraints on
short-selling -> leverage allowed
"""
function gmvp_lev(thisUniv::Univ)
  nObs = size(thisUniv)
  identVector = ones(nObs, 1)
  invMatr = inv(thisUniv.covs)
  gmvpWgts = vec((invMatr * identVector) ./ (identVector'*invMatr*identVector))
end


"""
    gmvp(thisUniv)

Get global minimum variance portfolio without short-selling.
"""
function gmvp(thisUniv)
    # set up optimization variables
    nAss = size(thisUniv)
    optVariables = Variable(nAss)

    # set up optimization problem
    numericallyScaledCovMatr = 1 * thisUniv.covs
    optProblem = minimize(quadform(optVariables, numericallyScaledCovMatr))
    identVector = ones(nAss, 1)
    optProblem.constraints += identVector'*optVariables == 1
    optProblem.constraints += optVariables .>= 0

    # solve and return solution
    solve!(optProblem)
    gmvpCvx = optVariables.value[:]
end

"""
    maxSharpe(thisUniv)

Get maximum Sharpe-ratio portfolio
"""
function maxSharpe(thisUniv::Univ)
    # set up optimization variables
    nAss = size(thisUniv)
    optVariables = Variable(nAss)

    # set up optimization problem
    numericallyScaledCovMatr = 1.^2 * thisUniv.covs
    numericallyScaledMus = 1 * thisUniv.mus
    optProblem = minimize(quadform(optVariables, numericallyScaledCovMatr))
    identVector = ones(nAss, 1)
    optProblem.constraints += numericallyScaledMus'*optVariables == 1
    optProblem.constraints += optVariables .>= 0

    # solve and return solution
    solve!(optProblem)
    maxSharpeWgts = optVariables.value / sum(optVariables.value)
    maxSharpeWgts = maxSharpeWgts[:]

end

"""
    sigmaTarget(thisUniv, thisTarget)

Get portfolio with maximum expected return for given target.
"""
function sigmaTarget(thisUniv::Univ, sigTarget::Float64)
    xWgts = sigmaTarget_cvx_reformulated(thisUniv, sigTarget)
    # xWgts = sigmaTarget_biSect_quadForm(thisUniv, sigTarget)
end

function sigmaTargetFallback(thisUniv::Univ, sigTarget::Float64)
    # get number of assets
    nAss = size(thisUniv)

    xWgts = []

    # if target sigma is too high to be reached at all
    # maxVal, maxInd = findmax(sqrt.(diag(thisUniv.covs)))
    # if sigTarget .>= maxVal
    #     xWgts = zeros(1, nAss)
    #     xWgts[maxInd] = 1
    #     return xWgts
    # end

    # if target sigma is too high to be reached efficiently
    maxMu, maxInd = findmax(thisUniv.mus)
    maxEffSig = sqrt.(diag(thisUniv.covs))[maxInd]
    if sigTarget .>= maxEffSig
        xWgts = zeros(Float64, nAss)
        xWgts[maxInd] = 1
        return xWgts
    end

    # if target sigma lower than lowest asset sigma
    minVal = minimum(sqrt.(diag(thisUniv.covs)))
    if sigTarget .<= minVal
        # if target sigma is too low to be reached
        xWgts = gmvp(thisUniv) # get gmv portfolio
        # get associated variance
        xxx, gmvVar = pfMoments(thisUniv, xWgts)
        if sigTarget < sqrt(gmvSigma)
            return xWgts
        end
    end

    return xWgts
end

function sigmaTarget_biSect_quadForm(thisUniv::Univ, sigTarget::Float64)

    xWgts = sigmaTargetFallback(thisUniv::Univ, sigTarget::Float64)

    # immediately return if fallback was required and sigma target is out of range
    if !(isempty(xWgts))
        return xWgts
    end

    # get number of assets
    nAss = size(thisUniv)

    # get mu range
    upBoundMu = maximum(thisUniv.mus)
    gmvpWgts = gmvp(thisUniv)
    lowBoundMu, lowBoundVar = pfMoments(thisUniv, gmvpWgts)

    # get mu mid-point
    midMu = (upBoundMu + lowBoundMu)./2

    # get associated sigma
    midMuPfWgts = muTarget(thisUniv, midMu)
    xx, midMuVar = pfMoments(thisUniv, midMuPfWgts)
    midMuSig = sqrt.(midMuVar)

    iterCount = 1
    iterLimit = 150
    while abs(midMuSig - sigTarget) > 0.004
        # get new mu bounds
        if midMuSig <= sigTarget
            lowBoundMu = midMu
        elseif midMuSig > sigTarget
            upBoundMu = midMu
        end

        # get new mu mid-point
        midMu = (upBoundMu + lowBoundMu)./2

        # get associated sigma
        midMuPfWgts = muTarget(thisUniv, midMu)
        xx, midMuVar = pfMoments(thisUniv, midMuPfWgts)
        midMuSig = sqrt.(midMuVar)

        if upBoundMu - lowBoundMu < 0.0001
            warn("Extremely horizontal efficient frontier region makes target sigma unreliably, so we stop here")
            return midMuPfWgts
        end

        # emergency break
        if iterCount .>= iterLimit
            error("Reached maximum number of bisection steps")
        end
        iterCount += 1

    end
    xWgts = midMuPfWgts

end

function sigmaTarget_cvx_reformulated(thisUniv::Univ, sigTarget::Float64)

    xWgts = sigmaTargetFallback(thisUniv::Univ, sigTarget::Float64)

    # immediately return if fallback was required and sigma target is out of range
    if !(isempty(xWgts))
        return xWgts
    end

    # get number of assets
    nAss = size(thisUniv)

    # define optimization variables
    x = Variable(nAss)
    y0 = Variable(1)
    y = Variable(nAss)

    socConstraint = [y, y0] in :SOC # TODO: does not work this way
    socConstraint2 = norm(y) .<= y0 # TODO: is not DCP compliant this way
    #xxTestConstraint = diag(y) in :SDP # TODO: correct syntax for SDP

    # get "square-root" of covariance matrix
    Qsqrt = sqrtm(thisUniv.covs)

    optProblem = maximize(thisUniv.mus'*x) # objective function

    # set up optimization problem
    identVector = ones(nAss, 1)
    optProblem.constraints += x .>= 0
    optProblem.constraints += sum(x) == 1
    optProblem.constraints += Qsqrt*x - y == 0
    optProblem.constraints += y0 == sigTarget
    #optProblem.constraints += xxTestConstraint # TODO: remove
    optProblem.constraints += socConstraint2
    solve!(optProblem)
    xWgts = x.value[:]

    # make test
    xxMu, xxVar = pfMoments(thisUniv, xWgts)
    truePfSig = sqrt.(xxVar)
    if abs(truePfSig - sigTarget) > 0.01
        warn("Sigma target optimization did not work well, trying fallback function")
        display("True sigma is $truePfSig")

        # try fallback
        xWgts2 = sigmaTarget_biSect_quadForm(thisUniv, sigTarget)
        xxMu, xxVar = pfMoments(thisUniv, xWgts2)
        truePfSig2 = sqrt.(xxVar)

        if abs(truePfSig - sigTarget) < abs(truePfSig2 - sigTarget)
            display("No improvement")
        else
            xWgts = xWgts2
            display("Fallback did show improved true sigma value of $truePfSig2")
        end
    end
    xWgts

end


function sigmaTarget_cvx_direct(thisUniv::Univ, sigTarget::Float64)

    # get number of assets
    nAss = size(thisUniv)

    # if target sigma is too high to be reached
    maxVal = maximum(sqrt.(diag(thisUniv.covs)))
    maxInd = findmax(sqrt.(diag(thisUniv.covs)))
    if sigTarget .>= maxVal
        xWgts = zeros(1, nAss)
        xWgts[maxInd] = 1
        return xWgts
    end

    # if target sigma lower than lowest asset sigma
    minVal = minimum(sqrt.(diag(thisUniv.covs)))
    if sigTarget .<= minVal
        # if target sigma is too low to be reached
        xWgts = gmvp(thisUniv) # get gmv portfolio
        get
        xxx, gmvSigma = pfMoments(thisUniv, xWgts)
        if sigTarget < gmvSigma
            return xWgts
        end
    end

    # define optimization variables
    x = Variable(nAss)
    y0 = Variable(1)
    y = Variable(nAss)

    socConstraint = [y, y0] in :SOC # TODO: does not work this way
    socConstraint2 = norm(y) .<= y0.^2 # TODO: is not DCP compliant this way
    #xxTestConstraint = diag(y) in :SDP # TODO: correct syntax for SDP

    # get "square-root" of covariance matrix
    Qsqrt = sqrtm(thisUniv.covs)

    optProblem = maximize(thisUniv.mus'*x) # objective function

    varianceTarget = sigTarget.^2

    # set up optimization problem
    identVector = ones(nAss, 1)
    optProblem.constraints += x .>= 0
    optProblem.constraints += sum(x) == 1
    optProblem.constraints += quadform(x, thisUniv.covs) .== varianceTarget
    solve!(optProblem)
    xWgts = x.value[:]

end


function muTarget(thisUniv::Univ, targetMu::Float64)
    # get number of assets
    nAss = size(thisUniv)

    x = Variable(nAss)

    numericallyScaledCovMatr = 1 .* thisUniv.covs
    numericallyScaledMus = 1 .* thisUniv.mus
    numericallyScaledTarget = 1 .* targetMu

    p = minimize(quadform(x, numericallyScaledCovMatr))

    p.constraints += x' * numericallyScaledMus >= numericallyScaledTarget
    p.constraints += sum(x) .== 1
    p.constraints += x .>= 0
    p.constraints += x .<= 1

    solve!(p)
    xWgts = x.value[:]

end


"""
    effFront(thisUniv; nEffPfs = 30)

Get efficient frontier portfolio weights
"""
function effFront(thisUniv::Univ; nEffPfs = 30)

    nAss = size(thisUniv)

    # get global minimum variance portfolio
    wgtsGmvp = gmvp(thisUniv)
    minMu, xx = pfMoments(thisUniv, wgtsGmvp)

    # get maximum mu
    maxMu, maxInd = findmax(thisUniv.mus)
    maxWgts = zeros(Float64, nAss)
    maxWgts[maxInd] = 1

    muGrid = [linspace(minMu, maxMu, nEffPfs)...]

    #effWgts = zeros(Float64, nEffPfs, nAss)
    effWgts = Array{Float64, 1}[]
    push!(effWgts, wgtsGmvp)
    #effWgts[1] = wgtsGmvp
    #effWgts[end] = maxWgts
    for ii=2:(nEffPfs-1)
        # get associated wgts
        #effWgts[ii] = muTarget(thisUniv, muGrid[ii])
        push!(effWgts, muTarget(thisUniv, muGrid[ii]))
    end
    push!(effWgts, maxWgts)

    return effWgts
end
