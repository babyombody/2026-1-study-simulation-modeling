using DrWatson
@quickactivate "project"

include(srcdir("SIRPetri.jl"))
using .SIRPetri
using DataFrames, CSV, Plots

ENV["GKSwstype"] = "100"

script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(plotsdir(script_name))

β = 0.3
γ = 0.1
tmax = 100.0

net, u0, _ = build_sir_network(β, γ)
df = simulate_deterministic(net, u0, (0.0, tmax), saveat=0.2, rates=[β, γ])

anim = @animate for row in eachrow(df)
    bar(
        ["S", "I", "R"],
        [row.S, row.I, row.R],
        legend=false,
        ylims=(0, 1000),
        xlabel="Compartment",
        ylabel="Population",
        title="SIR dynamics at t = $(round(row.time, digits=1))",
    )
end

gif(anim, plotsdir(script_name, "sir_animation.gif"), fps=10)
println("Анимация сохранена.")
