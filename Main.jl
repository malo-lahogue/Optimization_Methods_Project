#using Pkg
#Pkg.add("StatsBase")
#Pkg.add("Distributions")
#Pkg.add("GeometryBasics")
#Pkg.add("Ipopt")
#Pkg.add(["Juniper", "Ipopt", "GeometryBasics", "Distributions", "StatsBase"])
using Ipopt
using JuMP
using JuMP
using CSV
using DataFrames
using PowerModels
using Ipopt
using Juniper
using Plots
using GeometryBasics
using Distributed
addprocs()
println("Number of workers: ", nworkers())
@everywhere include("run_optimization.jl")
include("parallelized.jl")
include("scenario_generation.jl")



#generate the scenarios
S = 4 # Small right now, but change it later
seasons = rand(["winter", "spring", "summer", "fall"], S)
times = rand(1:24, S)

cf = [sample_cf(s, t) for (s, t) in zip(seasons, times)]
lf = [sample_load(s, t) for (s, t) in zip(seasons, times)]



#run the optimization model
data_path = "DATA/"
baseMVA = 10;

# Run the grid search
step_size = 0.25  # Define the step size for the grid search

# Run the grid search
results = grid_search_parallel(step_size, data_path, baseMVA, cf, lf)


output_file = "grid_search_results.csv"
CSV.write(output_file, results)