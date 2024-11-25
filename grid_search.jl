function grid_search(step_size, data_path, baseMVA, cf, lf)
    bus_data = CSV.read(string(data_path,"bus_data.csv"), DataFrame) |> Matrix
    num_busses = size(bus_data)[1]

    results = DataFrame(alpha=Float64[], beta=Float64[], gamma=Float64[], objective_total_cost=Float64[], obj_investment=Float64[], obj_V_index=Float64[], obj_Power_loss=Float64[])
    for i in 1:num_busses
        results[!, "pv_bus_$i"] = Float64[]
    end

    # Iterate over possible values of alpha and beta
    for alpha in 0:step_size:1
        for beta in 0:step_size:(1 - alpha)
            gamma = 1 - alpha - beta
            if gamma >= 0  # Ensure the constraint is satisfied
                # Calculate the objective cost
                cost, obj_inv, obj_V, obj_Ploss, capacity = run_optimization(data_path, baseMVA, alpha, beta, gamma, cf, lf)
                push!(results, (alpha, beta, gamma, cost, obj_inv, obj_V, obj_Ploss, capacity...))
            end
        end
    end

    return results
end