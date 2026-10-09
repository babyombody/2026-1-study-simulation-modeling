# # Параметрическое исследование модели SIR
# Исследуем влияние коэффициента заражения β и скорости выздоровления γ
# на динамику эпидемии: пик, время пика, итоговое число переболевших.

# ## Активация проекта и загрузка пакетов

using DrWatson
@quickactivate "project"

using DifferentialEquations
using DataFrames
using Plots
using JLD2
using BenchmarkTools

ENV["GKSwstype"] = "100"
gr(format=:png)

script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(plotsdir(script_name))
mkpath(datadir(script_name))

# ## Определение модели SIR
#
# ```
# dS/dt = -β c I S / N
# dI/dt =  β c I S / N - γ I
# dR/dt =  γ I
# ```

function sir_ode!(du, u, p, t)
    (S, I, R) = u
    (β, c, γ) = p
    N = S + I + R
    @inbounds begin
        du[1] = -β * c * I / N * S
        du[2] =  β * c * I / N * S - γ * I
        du[3] =  γ * I
    end
    nothing
end

# ## Базовые параметры эксперимента
#
# Все параметры собраны в `Dict` для систематизации.

base_params = Dict(
    :u0    => [[990.0, 10.0, 0.0]],  # S0, I0, R0
    :β     => 0.05,                   # вероятность передачи при контакте
    :c     => 10.0,                   # среднее число контактов
    :γ     => 0.25,                   # скорость выздоровления
    :tspan => [(0.0, 40.0)],          # временной интервал
    :solver => [Tsit5()],             # метод решения
    :saveat => [0.1]                  # шаг сохранения
)

println("Базовые параметры эксперимента:")
for (key, value) in base_params
    println("  $key = $value")
end

# ## Функция запуска одного эксперимента

function run_sir(params)
    prob = ODEProblem(sir_ode!, params[:u0], params[:tspan],
        (params[:β], params[:c], params[:γ]))
    sol = solve(prob, params[:solver]; saveat=params[:saveat])

    I = [u[2] for u in sol.u]
    R = [u[3] for u in sol.u]
    R0 = params[:c] * params[:β] / params[:γ]

    return Dict(
        "t"       => sol.t,
        "S"       => [u[1] for u in sol.u],
        "I"       => I,
        "R"       => R,
        "I_max"   => maximum(I),
        "t_peak"  => sol.t[argmax(I)],
        "R_inf"   => R[end],
        "R0"      => R0
    )
end

# ## Запуск базового эксперимента (одна комбинация)

base_params_single = dict_list(base_params)[1]
data, path = produce_or_load(
    datadir(script_name, "single"),
    base_params_single,
    run_sir;
    prefix = "sir_base",
    tag = false,
    verbose = true
)

println("\nРезультаты базового эксперимента:")
println("  R0              = ", round(data["R0"], digits=3))
println("  I_max           = ", round(data["I_max"], digits=1))
println("  t_peak          = ", round(data["t_peak"], digits=1), " дней")
println("  R(∞)            = ", round(data["R_inf"], digits=1))
println("  Файл результатов: ", path)

# ## Визуализация базового эксперимента

p1 = plot(data["t"], data["I"],
    label="I(t), β=$(base_params[:β]), γ=$(base_params[:γ])",
    xlabel="Время, дни", ylabel="Инфицированные",
    title="SIR: базовый эксперимент",
    lw=2, legend=:topleft, grid=true)
savefig(plotsdir(script_name, "sir_single.png"))

# ## Параметрическое сканирование по β и γ

param_grid = Dict(
    :u0    => [[990.0, 10.0, 0.0]],
    :β     => [0.03, 0.05, 0.08],     # исследуемые β
    :c     => [10.0],                 # фиксируем c
    :γ     => [0.1, 0.25, 0.4],       # исследуемые γ
    :tspan => [(0.0, 40.0)],
    :solver => [Tsit5()],
    :saveat => [0.1]
)

all_params = dict_list(param_grid)

println("\n" * "="^60)
println("ПАРАМЕТРИЧЕСКОЕ СКАНИРОВАНИЕ SIR")
println("Всего комбинаций: ", length(all_params))
println("Исследуемые β: ", param_grid[:β])
println("Исследуемые γ: ", param_grid[:γ])
println("="^60)

# ## Запуск всех экспериментов и сбор сводных результатов

all_results = []
all_dfs = []

for (i, params) in enumerate(all_params)
    println("Прогресс: $i/$(length(all_params)) | β=$(params[:β]), γ=$(params[:γ])")
    data, path = produce_or_load(
        datadir(script_name, "scan"),
        params,
        run_sir;
        prefix = "sir_scan",
        tag = false,
        verbose = false
    )
    result_summary = merge(params, Dict(
        :R0      => data["R0"],
        :I_max   => data["I_max"],
        :t_peak  => data["t_peak"],
        :R_inf   => data["R_inf"],
        :filepath => path
    ))
    push!(all_results, result_summary)

    df = DataFrame(
        t = data["t"],
        S = data["S"],
        I = data["I"],
        R = data["R"],
        β = fill(params[:β], length(data["t"])),
        γ = fill(params[:γ], length(data["t"]))
    )
    push!(all_dfs, df)
end

# ## Сводная таблица

results_df = DataFrame(all_results)
println("\nСводная таблица результатов:")
println(results_df[:, [:β, :γ, :R0, :I_max, :t_peak, :R_inf]])

# ## Сравнительный график всех траекторий I(t)

p2 = plot(size=(900, 500))
for params in all_params
    data, _ = produce_or_load(
        datadir(script_name, "scan"),
        params, run_sir;
        prefix = "sir_scan", tag = false, verbose = false
    )
    plot!(p2, data["t"], data["I"],
        label="β=$(params[:β]), γ=$(params[:γ])", lw=2, alpha=0.8)
end
plot!(p2,
    xlabel="Время, дни", ylabel="Инфицированные I(t)",
    title="SIR: влияние β и γ на динамику эпидемии",
    legend=:topright, grid=true)
savefig(plotsdir(script_name, "sir_parametric_comparison.png"))

# ## График R0 от параметров

p3 = plot(results_df.β, results_df.R0,
    seriestype=:scatter, group=results_df.γ,
    xlabel="β", ylabel="R0 = c·β/γ",
    title="Зависимость R0 от β и γ",
    markersize=8, legend=:topleft, grid=true)
hline!(p3, [1.0], color=:red, linestyle=:dash, label="Порог R0 = 1")
savefig(plotsdir(script_name, "sir_R0_vs_params.png"))

# ## График R(∞) от параметров

p4 = plot(results_df.β, results_df.R_inf ./ (results_df.β .* 0 .+ 1000),
    seriestype=:scatter, group=results_df.γ,
    xlabel="β", ylabel="Доля переболевших, %",
    title="Итоговая доля переболевших",
    markersize=8, legend=:topleft, grid=true)
savefig(plotsdir(script_name, "sir_R_inf_vs_params.png"))

# ## Бенчмаркинг для разных значений β

println("\n" * "="^60)
println("Бенчмаркинг для разных β")
println("="^60)

benchmark_results = []
for β_value in param_grid[:β]
    bench_params = Dict(
        :u0    => [990.0, 10.0, 0.0],
        :β     => β_value,
        :c     => 10.0,
        :γ     => 0.25,
        :tspan => (0.0, 40.0)
    )

    function benchmark_run()
        prob = ODEProblem(sir_ode!, bench_params[:u0], bench_params[:tspan],
            (bench_params[:β], bench_params[:c], bench_params[:γ]))
        return solve(prob, Tsit5(); saveat=0.1)
    end

    println("\nБенчмарк для β = $β_value:")
    b = @benchmark $benchmark_run() samples=100 evals=1
    push!(benchmark_results, (β=β_value, time=median(b).time/1e9))
    println("  Среднее время: ", round(median(b).time/1e9; digits=4), " сек")
end

bench_df = DataFrame(benchmark_results)
p5 = plot(bench_df.β, bench_df.time,
    seriestype=:scatter,
    label="Время решения",
    xlabel="β", ylabel="Время, сек",
    title="Зависимость времени решения от β",
    markersize=8, markercolor=:green, legend=:topleft, grid=true)
savefig(plotsdir(script_name, "sir_computation_time_vs_beta.png"))

# ## Сохранение всех результатов

@save datadir(script_name, "all_results.jld2") base_params param_grid all_params results_df bench_df
@save datadir(script_name, "all_plots.jld2") p1 p2 p3 p4 p5

println("\n" * "="^60)
println("ПАРАМЕТРИЧЕСКОЕ ИССЛЕДОВАНИЕ SIR ЗАВЕРШЕНО")
println("="^60)
println("\nРезультаты сохранены в:")
println("  • data/$script_name/single/         — базовый эксперимент")
println("  • data/$script_name/scan/           — параметрическое сканирование")
println("  • data/$script_name/all_results.jld2 — сводные данные")
println("  • plots/$script_name/               — все графики")
