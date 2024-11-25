#using Pkg
#Pkg.add(["Juniper", "Ipopt", "GeometryBasics", "Distributions", "StatsBase"])

using Distributed
addprocs()
println("Number of workers: ", nworkers())

@everywhere using JuMP, CSV, DataFrames, PowerModels, Ipopt, Juniper
@everywhere include("run_optimization.jl")
include("scenario_generation.jl")

function grid_search_parallel(step_size, data_path, baseMVA, cf, lf)
    # Read bus data and initialize the results DataFrame
    bus_data = CSV.read(string(data_path, "bus_data.csv"), DataFrame) |> Matrix
    num_busses = size(bus_data)[1]

    results = DataFrame(alpha=Float64[], beta=Float64[], gamma=Float64[], objective_total_cost=Float64[], obj_investment=Float64[], obj_V_index=Float64[], obj_Power_loss=Float64[])
    for i in 1:num_busses
        results[!, "pv_bus_$i"] = Float64[]
    end

    # Generate all combinations of alpha, beta, and gamma
    combinations = [(alpha, beta, 1 - alpha - beta)
                    for alpha in 0:step_size:1
                    for beta in 0:step_size:(1 - alpha)
                    if (1 - alpha - beta) >= 0]

    # Parallel computation using `pmap`
    parallel_results = pmap((comb) -> begin
    alpha, beta, gamma = comb
    run_optimization(data_path, baseMVA, alpha, beta, gamma, cf, lf)
    end, combinations)

    # Append results to the DataFrame
    for (alpha, beta, gamma, cost, obj_inv, obj_V, obj_Ploss, capacity) in parallel_results
        push!(results, (alpha, beta, gamma, cost, obj_inv, obj_V, obj_Ploss, capacity...))
    end

    return results
end


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
step_size = 0.5  # Define the step size for the grid search

# Run the grid search
results = grid_search_parallel(step_size, data_path, baseMVA, cf, lf)


output_file = "grid_search_results.csv"
CSV.write(output_file, results)




