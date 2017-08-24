
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
