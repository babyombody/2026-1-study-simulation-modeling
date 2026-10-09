using DrWatson
@quickactivate "project"

using DifferentialEquations
using DataFrames
using Plots
using Statistics
using FFTW
using JLD2
using BenchmarkTools

ENV["GKSwstype"] = "100"
gr(format=:png)

script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(plotsdir(script_name))
mkpath(datadir(script_name))

function lotka_volterra!(du, u, p, t)
    x, y = u
    α, β, δ, γ = p
    @inbounds begin
        du[1] = α*x - β*x*y
        du[2] = δ*x*y - γ*y
    end
    nothing
end

base_params_single = dict_list(base_params)[1]
base_params = Dict(
    :u0    => [[40.0, 9.0]],
    :α     => [0.1],
    :β     => [0.02],
    :δ     => [0.01],
    :γ     => [0.3],
    :tspan => [(0.0, 200.0)],
    :saveat => [0.1]
)

println("Базовые параметры эксперимента:")
for (key, value) in base_params
    println("  $key = $value")
end

function run_lv(params)
    prob = ODEProblem(lotka_volterra!, params[:u0], params[:tspan],
        (params[:α], params[:β], params[:δ], params[:γ]))
    sol = solve(prob, Tsit5();
        reltol=1e-8, abstol=1e-10, saveat=params[:saveat])

    prey     = [u[1] for u in sol.u]
    predator = [u[2] for u in sol.u]

    x_star = params[:γ] / params[:δ]   # равновесие жертв
    y_star = params[:α] / params[:β]   # равновесие хищников

    return Dict(
        "t"             => sol.t,
        "prey"          => prey,
        "predator"      => predator,
        "prey_mean"     => mean(prey),
        "predator_mean" => mean(predator),
        "prey_max"      => maximum(prey),
        "prey_min"      => minimum(prey),
        "predator_max"  => maximum(predator),
        "predator_min"  => minimum(predator),
        "x_star"        => x_star,
        "y_star"        => y_star
    )
end

base_params_single = dict_list(base_params)[1]
data, path = produce_or_load(
    datadir(script_name, "single"),
    base_params_single,
    run_lv;
    prefix = "lv_base",
    tag = false,
    verbose = true
)

println("\nРезультаты базового эксперимента:")
println("  x*       = ", round(data["x_star"], digits=3))
println("  y*       = ", round(data["y_star"], digits=3))
println("  <prey>   = ", round(data["prey_mean"], digits=2))
println("  <pred>   = ", round(data["predator_mean"], digits=2))
println("  Файл результатов: ", path)

p1 = plot(data["t"], [data["prey"] data["predator"]],
    label=["Жертвы x(t)" "Хищники y(t)"],
    xlabel="Время", ylabel="Популяция",
    title="Лотка-Вольтерра: базовый эксперимент",
    lw=2, legend=:topright, grid=true,
    color=[:green :red])
savefig(plotsdir(script_name, "lv_single.png"))

param_grid = Dict(
    :u0    => [[40.0, 9.0]],
    :α     => [0.05, 0.1, 0.2],       # исследуемые α
    :β     => [0.02],                 # фиксируем
    :δ     => [0.01],                 # фиксируем
    :γ     => [0.2, 0.3, 0.4],        # исследуемые γ
    :tspan => [(0.0, 200.0)],
    :saveat => [0.1]
)

all_params = dict_list(param_grid)

println("\n" * "="^60)
println("ПАРАМЕТРИЧЕСКОЕ СКАНИРОВАНИЕ ЛОТКИ-ВОЛЬТЕРРЫ")
println("Всего комбинаций: ", length(all_params))
println("Исследуемые α: ", param_grid[:α])
println("Исследуемые γ: ", param_grid[:γ])
println("="^60)

all_results = []
all_dfs = []

for (i, params) in enumerate(all_params)
    println("Прогресс: $i/$(length(all_params)) | α=$(params[:α]), γ=$(params[:γ])")
    data, path = produce_or_load(
        datadir(script_name, "scan"),
        params,
        run_lv;
        prefix = "lv_scan",
        tag = false,
        verbose = false
    )
    result_summary = merge(params, Dict(
        :x_star        => data["x_star"],
        :y_star        => data["y_star"],
        :prey_mean     => data["prey_mean"],
        :predator_mean => data["predator_mean"],
        :prey_max      => data["prey_max"],
        :prey_min      => data["prey_min"],
        :filepath      => path
    ))
    push!(all_results, result_summary)

    df = DataFrame(
        t        = data["t"],
        prey     = data["prey"],
        predator = data["predator"],
        α = fill(params[:α], length(data["t"])),
        γ = fill(params[:γ], length(data["t"]))
    )
    push!(all_dfs, df)
end

results_df = DataFrame(all_results)
println("\nСводная таблица результатов:")
println(results_df[:, [:α, :γ, :x_star, :y_star, :prey_mean, :predator_mean]])

p2 = plot(size=(900, 500))
for params in all_params
    data, _ = produce_or_load(
        datadir(script_name, "scan"),
        params, run_lv;
        prefix = "lv_scan", tag = false, verbose = false
    )
    plot!(p2, data["t"], data["prey"],
        label="α=$(params[:α]), γ=$(params[:γ])", lw=2, alpha=0.8)
end
plot!(p2,
    xlabel="Время", ylabel="Жертвы x(t)",
    title="Лотка-Вольтерра: влияние α и γ на жертв",
    legend=:topright, grid=true)
savefig(plotsdir(script_name, "lv_parametric_prey.png"))

p3 = plot(size=(900, 500))
for params in all_params
    data, _ = produce_or_load(
        datadir(script_name, "scan"),
        params, run_lv;
        prefix = "lv_scan", tag = false, verbose = false
    )
    plot!(p3, data["t"], data["predator"],
        label="α=$(params[:α]), γ=$(params[:γ])", lw=2, alpha=0.8)
end
plot!(p3,
    xlabel="Время", ylabel="Хищники y(t)",
    title="Лотка-Вольтерра: влияние α и γ на хищников",
    legend=:topright, grid=true)
savefig(plotsdir(script_name, "lv_parametric_predator.png"))

p4 = plot(size=(800, 600))
for params in all_params
    data, _ = produce_or_load(
        datadir(script_name, "scan"),
        params, run_lv;
        prefix = "lv_scan", tag = false, verbose = false
    )
    plot!(p4, data["prey"], data["predator"],
        label="α=$(params[:α]), γ=$(params[:γ])", lw=1.5, alpha=0.8)
end
plot!(p4,
    xlabel="Жертвы x", ylabel="Хищники y",
    title="Фазовые портреты при разных α и γ",
    legend=:topright, grid=true)
savefig(plotsdir(script_name, "lv_parametric_phase.png"))

function compute_dominant_period(signal, dt)
    n = length(signal)
    spectrum = abs.(rfft(signal .- mean(signal)))
    freq = rfftfreq(n, 1/dt)
    if length(spectrum) > 1
        idx = argmax(spectrum[2:end]) + 1
        return 1 / freq[idx]
    else
        return NaN
    end
end

periods = []
for params in all_params
    data, _ = produce_or_load(
        datadir(script_name, "scan"),
        params, run_lv;
        prefix = "lv_scan", tag = false, verbose = false
    )
    T = compute_dominant_period(data["prey"], 0.1)
    push!(periods, (α=params[:α], γ=params[:γ], period=T))
end

period_df = DataFrame(periods)
println("\nПериод колебаний жертв при разных α и γ:")
println(period_df)

p5 = plot(period_df.α, period_df.period,
    seriestype=:scatter, group=period_df.γ,
    xlabel="α", ylabel="Период колебаний T",
    title="Период колебаний жертв от α и γ",
    markersize=8, legend=:topright, grid=true)
savefig(plotsdir(script_name, "lv_period_vs_params.png"))

println("\n" * "="^60)
println("Бенчмаркинг для разных α")
println("="^60)

benchmark_results = []
for α_value in param_grid[:α]
    bench_params = Dict(
        :u0    => [40.0, 9.0],
        :α     => α_value,
        :β     => 0.02,
        :δ     => 0.01,
        :γ     => 0.3,
        :tspan => (0.0, 200.0)
    )

    function benchmark_run()
        prob = ODEProblem(lotka_volterra!, bench_params[:u0], bench_params[:tspan],
            (bench_params[:α], bench_params[:β], bench_params[:δ], bench_params[:γ]))
        return solve(prob, Tsit5(); reltol=1e-8, abstol=1e-10, saveat=0.1)
    end

    println("\nБенчмарк для α = $α_value:")
    b = @benchmark $benchmark_run() samples=50 evals=1
    push!(benchmark_results, (α=α_value, time=median(b).time/1e9))
    println("  Среднее время: ", round(median(b).time/1e9; digits=4), " сек")
end

bench_df = DataFrame(benchmark_results)
p6 = plot(bench_df.α, bench_df.time,
    seriestype=:scatter,
    label="Время решения",
    xlabel="α", ylabel="Время, сек",
    title="Зависимость времени решения от α",
    markersize=8, markercolor=:green, legend=:topleft, grid=true)
savefig(plotsdir(script_name, "lv_computation_time_vs_alpha.png"))

@save datadir(script_name, "all_results.jld2") base_params param_grid all_params results_df period_df bench_df
@save datadir(script_name, "all_plots.jld2") p1 p2 p3 p4 p5 p6

println("\n" * "="^60)
println("ПАРАМЕТРИЧЕСКОЕ ИССЛЕДОВАНИЕ ЛОТКИ-ВОЛЬТЕРРЫ ЗАВЕРШЕНО")
println("="^60)
println("\nРезультаты сохранены в:")
println("  • data/$script_name/single/         — базовый эксперимент")
println("  • data/$script_name/scan/           — параметрическое сканирование")
println("  • data/$script_name/all_results.jld2 — сводные данные")
println("  • plots/$script_name/               — все графики")
