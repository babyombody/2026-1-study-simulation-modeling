# # SIR: параметрическое сканирование β

using DrWatson
@quickactivate "project"

include(srcdir("sir_model.jl"))
using Random, StatsPlots, DataFrames, CSV, Statistics

ENV["GKSwstype"] = "100"

script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(plotsdir(script_name))
mkpath(datadir(script_name))

tmax = 40.0
u0 = [990, 10, 0]
betas = [0.03, 0.05, 0.07]
c_fixed = 10.0
γ_fixed = 0.25

results = []
all_data = DataFrame()

for β in betas
    Random.seed!(1234)
    p = [β, c_fixed, γ_fixed]
    m = MakeSIRModel(u0, p)
    activate(m)
    sir_run(m, tmax)
    data = out(m)

    peak_I = maximum(data.I)
    peak_t = data.t[argmax(data.I)]
    final_R = data.R[end]
    push!(results, (β=β, peak_I=peak_I, peak_t=peak_t, final_R=final_R))
    println("β = $β, peak_I = $peak_I, peak_t = $(round(peak_t, digits=2)), final_R = $final_R")

    data[!, :β] = fill(β, nrow(data))
    append!(all_data, data)
end

df = DataFrame(results)
CSV.write(datadir(script_name, "sir_scan.csv"), df)
CSV.write(datadir(script_name, "sir_all.csv"), all_data)

# ## График: сравнение I(t) для разных β
p1 = plot(size=(900, 500))
for β in betas
    sub = all_data[all_data.β .== β, :]
    plot!(p1, sub.t, sub.I, label="β = $β", lw=2)
end
plot!(p1, xlabel="Время", ylabel="Инфицированные",
    title="SIR: влияние β на динамику эпидемии", legend=:topright)
savefig(plotsdir(script_name, "sir_beta_comparison.png"))

# ## График: peak_I от β
p2 = plot(df.β, df.peak_I, marker=:circle, lw=2,
    xlabel="β", ylabel="Пик I",
    title="Зависимость пика от β")
savefig(plotsdir(script_name, "sir_peak_vs_beta.png"))

println("\nГотово!")
