#!/usr/bin/env julia
# add_packages.jl — пакеты для lab05 (Сети Петри, Обедающие философы)

using Pkg
Pkg.activate(".")

packages = [
    "DrWatson",
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

println("Установка пакетов для lab05...")
Pkg.add(packages)
println("\nВсе пакеты установлены!")
