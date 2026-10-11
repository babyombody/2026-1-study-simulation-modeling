# # Обедающие философы: итоговый отчёт
# Сравнение классической сети и сети с арбитром по динамике «Ест».

using DrWatson
@quickactivate "project"

using DataFrames, CSV, Plots

ENV["GKSwstype"] = "100"

script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(plotsdir(script_name))

df_classic = CSV.read(datadir("dining_philosophers", "dining_classic.csv"), DataFrame)
df_arbiter = CSV.read(datadir("dining_philosophers", "dining_arbiter.csv"), DataFrame)

N = 5
eat_cols = [Symbol("Eat_$i") for i in 1:N]

p1 = plot(df_classic.time, Matrix(df_classic[:, eat_cols]),
    label=["Ф $i" for i in 1:N],
    xlabel="Время", ylabel="Ест (1/0)",
    title="Классическая сеть")

p2 = plot(df_arbiter.time, Matrix(df_arbiter[:, eat_cols]),
    label=["Ф $i" for i in 1:N],
    xlabel="Время", ylabel="Ест (1/0)",
    title="Сеть с арбитром")

p_final = plot(p1, p2, layout=(2, 1), size=(800, 600))
savefig(plotsdir(script_name, "final_report.png"))

println("Отчёт сохранён в ", plotsdir(script_name, "final_report.png"))

