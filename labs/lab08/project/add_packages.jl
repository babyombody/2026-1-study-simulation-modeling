#!/usr/bin/env julia
# add_packages.jl — пакеты для lab08 (дискретно-событийная SIR-модель)

using Pkg
Pkg.activate(".")

packages = [
    "DrWatson",
    "ConcurrentSim",
    "ResumableFunctions",
    "Distributions",
    "StatsPlots",
    "DataFrames",
    "CSV",
    "BenchmarkTools",
    "JLD2",
    "Literate",
    "IJulia",
    "Quarto"
]

println("Установка пакетов для lab08...")
Pkg.add(packages)
println("\nВсе пакеты установлены!")
