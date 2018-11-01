using Pkg

PKGS = [
        "OhMyREPL",
        "CSV",
        "DataFrames",
        "Missings",
        "Parsers",
        "RData",
     ]

for pkg in PKGS
  if pkg ∉ keys(Pkg.installed())
    Pkg.add(pkg)
  end
end

using OhMyREPL
