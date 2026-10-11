# # SIR: базовый прогон (дискретно-событийная модель)

using DrWatson
@quickactivate "project"

include(srcdir("sir_model.jl"))
using Random, StatsPlots, DataFrames, CSV

ENV["GKSwstype"] = "100"

script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(plotsdir(script_name))
mkpath(datadir(script_name))

# ## Параметры
tmax = 40.0
u0 = [990, 10, 0]
p = [0.05, 10.0, 0.25]

Random.seed!(1234)

# ## Запуск
des_model = MakeSIRModel(u0, p)
activate(des_model)
sir_run(des_model, tmax)
data_des = out(des_model)

# ## Сохранение
CSV.write(datadir(script_name, "sir_des.csv"), data_des)

# ## Визуализация
@df data_des plot(
    :t, [:S :I :R],
    labels=["S" "I" "R"],
    xlab="Время", ylab="Численность",
    title="Дискретно-событийная SIR модель")
savefig(plotsdir(script_name, "sir_des.png"))

println("Готово! График: ", plotsdir(script_name, "sir_des.png"))
