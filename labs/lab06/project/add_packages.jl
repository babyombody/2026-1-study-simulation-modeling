#!/usr/bin/env julia
# add_packages.jl — пакеты для lab06 (SIR в сетях Петри)

using Pkg
Pkg.activate(".")

packages = [
    "DrWatson",
    "AlgebraicPetri",
    "Catlab",
    "OrdinaryDiffEq",
    "Plots",
    "DataFrames",
    "CSV",
    "JLD2",
    "Literate",
    "IJulia",
    "BenchmarkTools",
    "Quarto"
]

println("Установка пакетов для lab06...")
Pkg.add(packages)
println("\nВсе пакеты установлены!")
