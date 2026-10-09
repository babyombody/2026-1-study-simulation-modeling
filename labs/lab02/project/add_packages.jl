#!/usr/bin/env julia
# add_packages.jl — пакеты для lab02 (SIR + Lotka-Volterra)

using Pkg
Pkg.activate(".")

packages = [
    "DrWatson",
    "DifferentialEquations",
    "SimpleDiffEq",
    "Plots",
    "StatsPlots",
    "LaTeXStrings",
    "FFTW",
    "Statistics",
    "DataFrames",
    "CSV",
    "JLD2",
    "Literate",
    "IJulia",
    "BenchmarkTools",
    "Quarto"
]

println("Установка пакетов для lab02...")
Pkg.add(packages)
println("\nВсе пакеты установлены!")
