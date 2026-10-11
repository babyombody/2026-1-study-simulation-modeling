using DrWatson
@quickactivate "project"

using DataFrames, CSV, Plots

ENV["GKSwstype"] = "100"

script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(plotsdir(script_name))

df_det = CSV.read(datadir("sirpetri_run", "sir_det.csv"), DataFrame)
df_stoch = CSV.read(datadir("sirpetri_run", "sir_stoch.csv"), DataFrame)
df_scan = CSV.read(datadir("sirpetri_scan_parameters", "sir_scan.csv"), DataFrame)

p1 = plot(
    df_det.time,
    [df_det.I df_stoch.I[1:length(df_det.time)]],
    label=["Deterministic I" "Stochastic I"],
    xlabel="Time",
    ylabel="Infected",
    title="Comparison",
)
savefig(plotsdir(script_name, "comparison.png"))

p2 = plot(
    df_scan.β,
    df_scan.peak_I,
    marker=:circle,
    xlabel="β",
    ylabel="Peak I",
    title="Sensitivity",
)
savefig(plotsdir(script_name, "sensitivity.png"))

println("Отчётные графики сохранены.")
