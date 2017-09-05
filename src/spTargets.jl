# define single-period portfolio target types

# TODO: create super type!
# TODO: create collection of targets

abstract type SinglePeriodTarget end
abstract type SinglePeriodSpectrum end

struct GMVP <: SinglePeriodTarget

end

apply(xx::GMVP, thisUniv::Univ) = PF(gmvp(thisUniv))

struct TargetVola <: SinglePeriodTarget
    Vola::Float64
end

apply(xx::TargetVola, thisUniv::Univ) = PF(sigmaTarget(thisUniv, xx.Vola))

# vola relative to efficient frontier (maximum mu / gmvp mu range)
struct RelativeTargetVola <: SinglePeriodTarget
    Vola::Float64
end

struct MaxSharpe <: SinglePeriodTarget
    RiskFree::Float64
end

MaxSharpe() = MaxSharpe(0.0)
apply(xx::MaxSharpe, thisUniv::Univ) = PF(maxSharpe(thisUniv))

struct TargetMu <: SinglePeriodTarget
    Mu::Float64
end

apply(xx::TargetMu, thisUniv::Univ) = PF(muTarget(thisUniv, xx.Mu))

struct EffFront <: SinglePeriodSpectrum
    NEffPfs::Int64
end

function apply(xx::EffFront, thisUniv::Univ)
    wgtsArray = effFront(thisUniv; nEffPfs = xx.NEffPfs)
    pfArray = map(x -> PF(x), wgtsArray)
    pfArray = reshape(pfArray, 1, size(pfArray, 1))
end

function getSingleTargets(someFront::EffFront)
    # get number of portfolios
    nPfs = someFront.NEffPfs

    allSingleStrats = [RelativeTargetVola(ii./nPfs) for ii=1:nPfs]
end

## generalization of apply

# make generalization to UnivEvols including potential parallelization
function apply(thisTarget::SinglePeriodTarget, univHistory::UnivEvol)
    # check for multiple processes

    nProcesses = nprocs()

    if nProcesses == 1
        allPfs = [apply(thisTarget, x) for x in univHistory.universes]
        allPfs = reshape(allPfs, size(allPfs, 1), 1)

    elseif nProcesses > 1

        # distribute historic universes over processes
        DUnivs = distribute(univHistory.universes)

        allWgtsDistributed = map(x -> apply(thisTarget, x), DUnivs)
        allPfs = convert(Array, allWgtsDistributed)

        allPfs = reshape(allPfs, size(allPfs, 1), 1)

    end

end

# make generalization to UnivEvols including potential parallelization
function apply(thisTarget::SinglePeriodSpectrum, univHistory::UnivEvol)
    # check for multiple processes

    nProcesses = nprocs()

    if nProcesses == 1
        allPfs = [apply(thisTarget, x) for x in univHistory.universes]
        allPfs = vcat(allPfs...)

    elseif nProcesses > 1

        # distribute historic universes over processes
        DUnivs = distribute(univHistory.universes)

        allWgtsDistributed = map(x -> apply(thisTarget, x), DUnivs)
        allPfs = convert(Array, allWgtsDistributed)
        allPfs = vcat(allPfs...)

    end
    return allPfs
end
