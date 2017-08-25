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
function maxSharpe(thisUniv)
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
