using Pkg

PKGS = [
        "OhMyREPL",
        "CSV",
        "DataFrames",
        "Missings",
        "Parsers",
        "RData",
       ]

deps = [pair.second.name for pair in Pkg.dependencies()]

for pkg in PKGS
  if pkg ∉ deps
    Pkg.add(pkg)
  end
end

using OhMyREPL
