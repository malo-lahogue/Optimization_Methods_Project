# Import the required packages
using JuMP
using Ipopt

# Create a new optimization model using Ipopt as the solver
model = Model(Ipopt.Optimizer)

# Define the variables with bounds
@variable(model, x1 >= 0)  # x1 ≥ 0
@variable(model, x2 >= 0)  # x2 ≥ 0

# Define the objective function
@objective(model, Min, (x1 - 1)^2 + (x2 - 2)^2)

# Define the constraints
@constraint(model, x1^2 + x2^2 <= 1)  # Circle constraint

# Solve the optimization problem
optimize!(model)

# Extract the solution
x1_opt = value(x1)
x2_opt = value(x2)
optimal_value = objective_value(model)

# Display the results
println("Optimal solution:")
println("x1 = $x1_opt")
println("x2 = $x2_opt")
println("Objective value = $optimal_value")
