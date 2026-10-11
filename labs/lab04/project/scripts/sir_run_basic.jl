# # SIR: базовый эксперимент
# Один прогон модели с параметрами по умолчанию.

# ## Загрузка

using DrWatson
@quickactivate "project"

using Agents, DataFrames, Plots
using JLD2

ENV["GKSwstype"] = "100"

include(srcdir("sir_model.jl"))

script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(plotsdir(script_name))
mkpath(datadir(script_name))

# ## Параметры

params = Dict(
    :Ns => [1000, 1000, 1000],
    :β_und => [0.5, 0.5, 0.5],
    :β_det => [0.05, 0.05, 0.05],
    :infection_period => 14,
    :detection_time => 7,
    :death_rate => 0.02,
    :reinfection_probability => 0.1,
    :Is => [0, 0, 1],
    :seed => 42,
    :n_steps => 100
)

# ## Инициализация

model = initialize_sir(; params...)

times = Int[]
S_vals = Int[]
I_vals = Int[]
R_vals = Int[]
total_vals = Int[]

# ## Симуляция

for step in 1:params[:n_steps]
    Agents.step!(model, 1)
    push!(times, step)
    push!(S_vals, susceptible_count(model))
    push!(I_vals, infected_count(model))
    push!(R_vals, recovered_count(model))
    push!(total_vals, total_count(model))
end

agent_df = DataFrame(time=times, susceptible=S_vals,
                     infected=I_vals, recovered=R_vals)
model_df = DataFrame(time=times, total=total_vals)

# ## Визуализация

plt = plot(agent_df.time, agent_df.susceptible,
    label="Восприимчивые", xlabel="Дни", ylabel="Количество", lw=2)
plot!(plt, agent_df.time, agent_df.infected, label="Инфицированные", lw=2)
plot!(plt, agent_df.time, agent_df.recovered, label="Выздоровевшие", lw=2)
plot!(plt, model_df.time, model_df.total,
    label="Всего (включая умерших)", linestyle=:dash, lw=2)

savefig(plotsdir(script_name, "sir_basic_dynamics.png"))

# ## Сохранение

@save datadir(script_name, "sir_basic_agent.jld2") agent_df
@save datadir(script_name, "sir_basic_model.jld2") model_df

println("Готово! График: ", plotsdir(script_name, "sir_basic_dynamics.png"))
