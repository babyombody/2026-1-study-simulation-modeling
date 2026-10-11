#!/usr/bin/env julia
# add_packages.jl — пакеты для lab07 (дискретно-событийное моделирование)

using Pkg
Pkg.activate(".")

packages = [
    "DrWatson",
    "ConcurrentSim",       # дискретно-событийное моделирование
    "ResumableFunctions",  # @resumable и @yield
    "StableRNGs",          # воспроизводимые ГПСЧ
    "Distributions",       # Exponential
    "DataFrames",
    "CSV",
    "Plots",
    "JLD2",
    "Literate",
    "IJulia",
    "BenchmarkTools",
    "Quarto"
]

println("Установка пакетов для lab07...")
Pkg.add(packages)
println("\nВсе пакеты установлены!")
