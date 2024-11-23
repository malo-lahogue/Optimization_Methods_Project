function grid_search(step_size, data_path, baseMVA, cf, lf)
    results = DataFrame(alpha=Float64[], beta=Float64[], gamma=Float64[], objective_cost=Float64[])

    # Iterate over possible values of alpha and beta
    for alpha in 0:step_size:1
        for beta in 0:step_size:(1 - alpha)
            gamma = 1 - alpha - beta
            if gamma >= 0  # Ensure the constraint is satisfied
                # Calculate the objective cost
                cost, capacity = run_optimization(data_path, baseMVA, alpha, beta, gamma, cf, lf)
                # Append the results to the DataFrame
                push!(results, (alpha, beta, gamma, cost))
            end
        end
    end

    return results
end