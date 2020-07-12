using Monadic
using Documenter

makedocs(;
    modules=[Monadic],
    authors="Stephan Sahm and contributors",
    repo="https://github.com/schlichtanders/Monadic.jl/blob/{commit}{path}#L{line}",
    sitename="Monadic.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://schlichtanders.github.io/Monadic.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Manual" => "manual.md",
        "API" => "api.md",
    ],
)

deploydocs(;
    repo="github.com/schlichtanders/Monadic.jl",
)
