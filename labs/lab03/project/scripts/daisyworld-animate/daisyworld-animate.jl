using DrWatson
@quickactivate "project"

using Agents
using DataFrames
using Plots
using CairoMakie

ENV["GKSwstype"] = "100"

include(srcdir("daisyworld.jl"))

script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(plotsdir(script_name))

model = daisyworld()

daisycolor(a::Daisy) = a.breed

plotkwargs = (
    agent_color = daisycolor,
    agent_size = 20,
    agent_marker = '♠',
    heatarray = :temperature,
    heatkwargs = (colorrange = (-20, 60),)
)

abmvideo(
    plotsdir(script_name, "simulation.mp4"),
    model;
    title = "Daisy World",
    frames = 60,
    plotkwargs...
)

println("Видео сохранено в ", plotsdir(script_name, "simulation.mp4"))
