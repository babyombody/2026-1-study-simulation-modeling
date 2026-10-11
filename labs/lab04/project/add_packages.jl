#!/usr/bin/env julia
# add_packages.jl — пакеты для lab04 (SIR в агентном подходе)

using Pkg
Pkg.activate(".")

packages = [
    "DrWatson",
    "Agents",           # агентное моделирование
    "Graphs",           # графы (GraphSpace)
    "Distributions",    # Poisson для заражения
    "StatsBase",        # sample, Weights
    "BlackBoxOptim",    # многокритериальная оптимизация
    "DataFrames",
    "CSV",
    "Plots",
    "JLD2",
    "Literate",
    "IJulia",
    "BenchmarkTools",
    "Quarto"
]

println("Установка пакетов для lab04...")
Pkg.add(packages)
println("\nВсе пакеты установлены!")
