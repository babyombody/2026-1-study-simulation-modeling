using DrWatson
@quickactivate "project"

using ResumableFunctions
using ConcurrentSim
using Distributions
using Random
using StableRNGs
using DataFrames, CSV, Plots, Statistics

ENV["GKSwstype"] = "100"

script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(plotsdir(script_name))
mkpath(datadir(script_name))

const RUNS   = 2          # один прогон на точку — быстро
const N      = 10          # 5 основных машин (меньше событий)
const SEED   = 150
const LAMBDA = 100.0
const MU     = 1.0

@resumable function machine(env::Environment, repair_facility::Resource,
                            spares::Store{Process}, rng)
    while true
        try
            @yield timeout(env, Inf)
        catch
        end
        @yield timeout(env, rand(rng, Exponential(LAMBDA)))

        get_spare = take!(spares)
        @yield get_spare | timeout(env)

        if state(get_spare) != ConcurrentSim.idle
            @yield interrupt(value(get_spare))
        else
            throw(StopSimulation("No more spares!"))
        end

        @yield request(repair_facility)
        @yield timeout(env, rand(rng, Exponential(MU)))
        @yield unlock(repair_facility)
        @yield put!(spares, active_process(env))
    end
end

@resumable function start_sim(env::Environment, repair_facility::Resource,
                              spares::Store{Process}, N, S, rng)
    for i in 1:N
        proc = @process machine(env, repair_facility, spares, rng)
        @yield interrupt(proc)
    end
    for i in 1:S
        proc = @process machine(env, repair_facility, spares, rng)
        @yield put!(spares, proc)
    end
end

function sim_repair(; N=N, S=3, seed=SEED)
    rng = StableRNG(seed)
    sim = Simulation()
    repair_facility = Resource(sim)
    spares = Store{Process}(sim)

    @process start_sim(sim, repair_facility, spares, N, S, rng)

    try
        run(sim)
    catch e
        if !isa(e, StopSimulation)
            rethrow(e)
        end
    end
    return now(sim)
end

println("=== Модель Росса ===")
println("N = $N, S = 3, LAMBDA = $LAMBDA, MU = $MU")

results = Float64[]
for i in 1:RUNS
    push!(results, sim_repair(S=3, seed=SEED + i))
end
println("Crash time (S=3): ", round(mean(results), digits=2))

println("\n=== Сканирование S ===")
S_range = [1, 2, 3, 5]
scan_results = []
for s_val in S_range
    rs = Float64[]
    for i in 1:RUNS
        push!(rs, sim_repair(S=s_val, seed=SEED + i))
    end
    avg_s = mean(rs)
    push!(scan_results, (S=s_val, crash_time=avg_s))
    println("S = $s_val, crash time = $(round(avg_s, digits=2))")
end

df = DataFrame(scan_results)
CSV.write(datadir(script_name, "ross_scan.csv"), df)

p = plot(df.S, df.crash_time,
    marker=:circle,
    xlabel="Число запасных машин S",
    ylabel="Среднее время до отказа",
    title="Модель Росса: зависимость времени до отказа от S")
savefig(plotsdir(script_name, "ross_scan.png"))

println("\nГотово! Результаты: ", datadir(script_name, "ross_scan.csv"))
