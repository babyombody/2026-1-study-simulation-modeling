# # Модель M/M/c (система массового обслуживания)
# Стохастическая симуляция через дискретно-событийное моделирование (ConcurrentSim).

using DrWatson
@quickactivate "project"

using StableRNGs
using Distributions
using ConcurrentSim
using ResumableFunctions
using DataFrames, CSV, Plots, Statistics

ENV["GKSwstype"] = "100"

script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(plotsdir(script_name))
mkpath(datadir(script_name))

# ## Параметры симуляции
rng = StableRNG(123)
num_customers = 100          # общее число клиентов
num_servers = 2              # число серверов
mu = 1.0 / 2                 # интенсивность обслуживания
lam = 0.9                    # интенсивность прибытия
arrival_dist = Exponential(1 / lam)   # распределение интервалов прибытия
service_dist = Exponential(1 / mu)    # распределение времени обслуживания

# ## Поведение клиента
@resumable function customer(env::Environment, server::Resource, id::Integer,
                              t_a::Float64, d_s::Distribution)
    @yield timeout(env, t_a)
    arrival_time = now(env)
    println("Customer $id arrived: ", arrival_time)

    @yield request(server)
    service_start = now(env)
    println("Customer $id entered service: ", service_start)

    service_time = rand(rng, d_s)
    @yield timeout(env, service_time)

    @yield unlock(server)
    service_end = now(env)
    println("Customer $id exited service: ", service_end)
end

# ## Функция запуска симуляции
function setup_and_run()
    sim = Simulation()
    server = Resource(sim, num_servers)

    arrival_time = 0.0
    for i in 1:num_customers
        arrival_time += rand(rng, arrival_dist)
        @process customer(sim, server, i, arrival_time, service_dist)
    end
    run(sim)
end

println("=== Симуляция M/M/c ===")
setup_and_run()

# ## Параметрическое исследование: сканирование λ
lambdas = [0.5, 0.9, 1.2, 1.5]
results = []

for lam_val in lambdas
    rng_local = StableRNG(42)
    arrival_dist_local = Exponential(1 / lam_val)
    service_dist_local = Exponential(1 / mu)
    sim = Simulation()
    server = Resource(sim, num_servers)
    arrival_time = 0.0
    service_times = Float64[]
    wait_times = Float64[]
    for i in 1:num_customers
        arrival_time += rand(rng_local, arrival_dist_local)
        service_time = rand(rng_local, service_dist_local)
        push!(service_times, service_time)
        push!(wait_times, max(0.0, service_time - (arrival_time / num_customers)))
    end
    rho = lam_val / (num_servers * mu)
    push!(results, (
        lambda = lam_val,
        rho = rho,
        mean_wait = mean(wait_times),
        mean_service = mean(service_times)
    ))
    println("λ = $lam_val, ρ = $(round(rho, digits=3))")
end

df = DataFrame(results)
CSV.write(datadir(script_name, "mmc_scan.csv"), df)

# ## График
p = plot(df.lambda, [df.mean_wait df.mean_service],
    label=["Среднее ожидание" "Среднее обслуживание"],
    marker=:circle,
    xlabel="λ (интенсивность прибытия)",
    ylabel="Время",
    title="M/M/$(num_servers): зависимость от λ")
savefig(plotsdir(script_name, "mmc_scan.png"))

println("\nСканирование λ завершено.")
println(df)
