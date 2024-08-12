using CompositionalMLStudy
using Documenter

DocMeta.setdocmeta!(CompositionalMLStudy, :DocTestSetup, :(using CompositionalMLStudy); recursive=true)

makedocs(;
    modules=[CompositionalMLStudy],
    authors="TheCedarPrince <jacobszelko@gmail.com> and contributors",
    sitename="CompositionalMLStudy.jl",
    format=Documenter.HTML(;
        canonical="https://TheCedarPrince.github.io/CompositionalMLStudy.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/TheCedarPrince/CompositionalMLStudy.jl",
    devbranch="main",
)
