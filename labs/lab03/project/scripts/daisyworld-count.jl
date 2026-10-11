# # Daisyworld: динамика числа маргариток
# График изменения числа чёрных и белых маргариток во времени.

# ## Загрузка

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
mkpath(datadir(script_name))

# ## Данные агентов

black(a) = a.breed == :black
white(a) = a.breed == :white
adata = [(black, count), (white, count)]

# ## Модель и запуск

model = daisyworld(; solar_luminosity = 1.0)
agent_df, model_df = run!(model, 1000; adata)

# ## Визуализация (CairoMakie)

figure = Figure(size = (600, 400))
ax = figure[1, 1] = Axis(figure, xlabel = "tick", ylabel = "daisy count")
blackl = lines!(ax, agent_df[!, :time], agent_df[!, :count_black], color = :black)
whitel = lines!(ax, agent_df[!, :time], agent_df[!, :count_white], color = :orange)
Legend(figure[1, 2], [blackl, whitel], ["black", "white"], labelsize = 12)

# ## Сохранение

save(plotsdir(script_name, "daisy_count.png"), figure)

println("График сохранён!")
