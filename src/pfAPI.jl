## define Portfolio API

struct PF
    Wgts::Array{Float64, 1}

    function PF(xx)
        if abs(sum(xx) - 1) > 0.001
            error("Portfolio weights must sum to 1")
        end
        if any(xx .>= 0)
            error("All portfolio weights need to be positive")
        end

        return new(xx)
    end
end

##

import Base.size
size(pf::PF) = size(pf.Wgts, 1)

import Base.convert
function convert(::Type{Array{Float64, 2}}, xx::Array{PF, 1})
    nPfs = size(xx, 1)
    nAss = size(xx[1])

    allWgts = zeros(Float64, nPfs, nAss)
    for ii=1:nPfs
        allWgts[ii, :] = xx[ii].Wgts'
    end
    return allWgts
end


## Investments

struct Invest
    pfs::Array{PF, 2}
    strategies::Array{SinglePeriodTarget, 1}
    dates::Array{Date, 1}
    assetLabels::Array{Symbol, 1}
end

function Invest(pfs::Array{PF, 2}, spectrum::SinglePeriodSpectrum, dates::Array{Date, 1}, assetLabels::Array{Symbol, 1})
    strats = getSingleTargets(spectrum)
    return Invest(pfs, strats, dates, assetLabels)
end

import Base.size
size(inv::Invest) = (size(inv.dates, 1), size(inv.strategies, 1), size(inv.assetLabels, 1))
