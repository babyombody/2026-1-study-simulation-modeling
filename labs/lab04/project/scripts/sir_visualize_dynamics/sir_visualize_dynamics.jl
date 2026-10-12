import Pkg
Pkg.activate("/home/dabakharev/work/study/2026-1/2026-1==study-simulation-modeling/2026-1-study-simulation-modeling/labs/lab04/project")
using DrWatson
using DataFrames, CSV, Plots

ENV["GKSwstype"] = "100"

script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(plotsdir(script_name))

csv_file = datadir("sir_scan_beta", "beta_scan_all.csv")
if !isfile(csv_file)
    error("Файл не найден: $csv_file. Сначала запустите scripts/sir_scan_beta.jl")
end

df = CSV.read(csv_file, DataFrame)

plt = plot(layout=(3, 1), size=(800, 900))

plot!(plt[1], df.beta, df.peak,
    label="Пик", xlabel="β", ylabel="Доля инфицированных",
    marker=:circle, lw=2)
plot!(plt[1], df.beta, df.final_inf,
    label="Конечная доля инфицированных", marker=:square, lw=2)

plot!(plt[2], df.beta, df.deaths,
    label="Число умерших", xlabel="β", ylabel="Умершие",
    marker=:diamond, lw=2, color=:red)

plot!(plt[3], df.beta, df.final_rec,
    label="Доля выздоровевших", xlabel="β", ylabel="Доля выздоровевших",
    marker=:utriangle, lw=2, color=:green)

savefig(plotsdir(script_name, "comprehensive_analysis.png"))
println("Готово!")
