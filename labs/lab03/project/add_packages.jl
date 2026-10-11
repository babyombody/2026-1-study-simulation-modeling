#!/usr/bin/env julia
# add_packages.jl — пакеты для lab03 (Daisyworld, Agents.jl)

using Pkg
Pkg.activate(".")

packages = [
    "DrWatson",
    "Agents",          # агентное моделирование
    "CairoMakie",      # визуализация (для Agents.jl)
    "StatsBase",       # sample, mean
    "DataFrames",
    "Plots",
    "CSV",
    "JLD2",
    "Literate",
    "IJulia",
    "BenchmarkTools",
    "Quarto"
]

println("Установка пакетов для lab03...")
Pkg.add(packages)
println("\nВсе пакеты установлены!")
