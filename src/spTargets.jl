# define single-period portfolio target types

# TODO: create super type!
# TODO: create collection of targets

abstract type SinglePeriodTarget end

struct GMVP <: SinglePeriodTarget

end

apply(xx::GMVP, thisUniv::Univ) = gmvp(thisUniv)

struct TargetVola <: SinglePeriodTarget
    Vola::Float64
end

apply(xx::TargetVola, thisUniv::Univ) = sigmaTarget(thisUniv, xx.Vola)

struct MaxSharpe <: SinglePeriodTarget
    RiskFree::Float64
end

MaxSharpe() = MaxSharpe(0.0)
apply(xx::MaxSharpe, thisUniv::Univ) = maxSharpe(thisUniv)

struct TargetMu <: SinglePeriodTarget
    Mu::Float64
end

apply(xx::TargetMu, thisUniv::Univ) = muTarget(thisUniv, xx.Mu)

# make generalization to UnivEvols including potential parallelization
function apply(thisTarget::SinglePeriodTarget, univHistory::UnivEvol)
    # check for multiple processes

    nProcesses = nprocs()

    if nProcesses == 1
        allWgts = [apply(thisTarget, x) for x in univHistory.universes]
        allWgts = vcat([ii[:]' for ii in allWgts]...)

    elseif nProcesses > 1

        # distribute historic universes over processes
        DUnivs = distribute(univHistory.universes)

        allWgtsDistributed = map(x -> apply(thisTarget, x), DUnivs)
        allWgts = convert(Array, allWgtsDistributed)
        allWgts = vcat([ii[:]' for ii in allWgts]...)

    end

end
