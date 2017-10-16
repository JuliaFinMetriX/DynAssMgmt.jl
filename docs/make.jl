using Documenter, DynAssMgmt

makedocs()

deploydocs(
    deps   = Deps.pip("mkdocs", "python-markdown-math"),
    repo   = "github.com/JuliaFinMetriX/DynAssMgmt.jl.git",
    julia  = "0.6",
    osname = "linux"
)
