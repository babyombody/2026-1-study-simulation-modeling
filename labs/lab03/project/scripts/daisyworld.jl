# # Daisyworld: базовая визуализация
# Модель Daisyworld: чёрные и белые маргаритки регулируют температуру планеты.

# ## Активация проекта и загрузка пакетов

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

# ## Создание модели

model = daisyworld()

# ## Цвет маргариток — по виду

daisycolor(a::Daisy) = a.breed

plotkwargs = (
    agent_color = daisycolor,
    agent_size = 20,
    agent_marker = '♠',
    heatarray = :temperature,
    heatkwargs = (colorrange = (-20, 60),)
)

# ## Визуализация: шаг 0

plt1, _ = abmplot(model; plotkwargs...)

# ## Визуализация: шаг 5

step!(model, 5)
plt2, _ = abmplot(model; heatarray = model.temperature, plotkwargs...)

# ## Визуализация: шаг 40

step!(model, 40)
plt3, _ = abmplot(model; heatarray = model.temperature, plotkwargs...)

# ## Сохранение результатов

save(plotsdir(script_name, "daisy_step001.png"), plt1)
save(plotsdir(script_name, "daisy_step005.png"), plt2)
save(plotsdir(script_name, "daisy_step040.png"), plt3)

println("Готово! Графики сохранены в ", plotsdir(script_name))
