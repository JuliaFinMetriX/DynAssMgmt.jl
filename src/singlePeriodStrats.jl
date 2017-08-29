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
    optProblem = minimize(quadform(optVariables, thisUniv.covs))
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
    optProblem = minimize(quadform(optVariables, thisUniv.covs))
    identVector = ones(nAss, 1)
    optProblem.constraints += thisUniv.mus'*optVariables == 1
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

end


function cappedSigma(thisUniv::Univ, sigTarget::Float64)

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

    p = minimize(quadform(x, thisUniv.covs))

    p.constraints += x' * thisUniv.mus >= targetMu
    p.constraints += sum(x) .== 1
    p.constraints += x .>= 0
    p.constraints += x .<= 1

    solve!(p)
    xWgts = x.value[:]

end
