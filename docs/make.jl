using Documenter, DynAssMgmt

makedocs()

deploydocs(
    deps   = Deps.pip("mkdocs", "python-markdown-math"),
    repo   = "github.com/cgroll/DynAssMgmt.git",
    julia  = "0.5",
    osname = "linux"
)
