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

param_dict = Dict(
    :griddims => (30, 30),
    :max_age => [25, 40],
    :init_white => [0.2, 0.8],
    :init_black => 0.2,
    :albedo_white => 0.75,
    :albedo_black => 0.25,
    :surface_albedo => 0.4,
    :solar_change => 0.005,
    :solar_luminosity => 1.0,
    :scenario => :default,
    :seed => 165,
)

params_list = dict_list(param_dict)
println("Всего комбинаций: ", length(params_list))

for params in params_list
    println("Прогон: ", params)
    model = daisyworld(; params...)

    daisycolor(a::Daisy) = a.breed
    plotkwargs = (
        agent_color = daisycolor,
        agent_size = 20,
        agent_marker = '♠',
        heatarray = :temperature,
        heatkwargs = (colorrange = (-20, 60),)
    )

    plt1, _ = abmplot(model; plotkwargs...)
    step!(model, 5)
    plt2, _ = abmplot(model; heatarray = model.temperature, plotkwargs...)
    step!(model, 40)
    plt3, _ = abmplot(model; heatarray = model.temperature, plotkwargs...)

    name1 = savename("daisyworld", params) * "_step01.png"
    name2 = savename("daisyworld", params) * "_step05.png"
    name3 = savename("daisyworld", params) * "_step40.png"

    save(plotsdir(script_name, name1), plt1)
    save(plotsdir(script_name, name2), plt2)
    save(plotsdir(script_name, name3), plt3)
end

println("Готово!")
