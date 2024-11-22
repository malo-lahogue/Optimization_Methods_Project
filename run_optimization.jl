function run_optimization(data_path, baseMVA, beta, gamma, cf, lf)

    bus_data = CSV.read(string(data_path,"bus_data.csv"), DataFrame) |> Matrix;
    (num_busses, var) = size(bus_data);
    VMax = bus_data[:, 4];
    VMin = bus_data[:, 7]; 
    load_data = CSV.read(string(data_path,"load_data.csv"), DataFrame) |> Matrix;
    (num_loads, var) = size(load_data);
    branch_data = CSV.read(string(data_path,"branch_data.csv"), DataFrame) |> Matrix;
    (num_branches, var) = size(branch_data)
    G = CSV.read(string(data_path,"G_mat.csv"), DataFrame) |> Matrix;
    B = CSV.read(string(data_path,"B_mat.csv"), DataFrame)|> Matrix;
    #number of scenarios
    S  = length(cf);

    #Expand the Pd data such that non load busses are given power demands of 0
    Pd = load_data[:,5]*baseMVA
    load_busses = load_data[:,2];
    bus_idx = bus_data[:,2]; 
    Pd_mod = zeros(1, num_busses);
    for i = 1:num_busses
        idx = findall(isequal(bus_idx[i]), load_busses)
        if !isempty(idx)
            Pd_mod[i] = Pd[idx[1]]
        else
            Pd_mod[i] = 0;
        end
    end
    Pd = Pd_mod

    Qd = load_data[:,4]*baseMVA
    Qd_mod = zeros(1, num_busses);
    for i = 1:num_busses
        idx = findall(isequal(bus_idx[i]), load_busses)
        if !isempty(idx)
            Qd_mod[i] = Qd[idx[1]]
        else
            Qd_mod[i] = 0;
        end
    end
    Qd = Qd_mod
    #optimizer = Juniper.Optimizer
    #nl_solver = optimizer_with_attributes(Ipopt.Optimizer, "print_level" => 0)

    model = Model(Ipopt.Optimizer)

    #Number of scenarios
    S = 100;

    @variable(model, V[1:num_busses, 1:S] >= 0)
    @variable(model, theta[1:num_busses, 1:S])
    @variable(model, PG[1:num_busses, 1:S] >= 0)
    @variable(model, QG[1:num_busses, 1:S] >= 0)
    @variable(model, y[1:num_busses] >= 0)
    #@variable(model, x[1:num_busses], Bin)
    @variable(model, Ploss[1:num_busses, 1:S] >= 0)
    @variable(model, Qloss[1:num_busses, 1:S] >= 0)
    @variable(model, I[1:num_busses, 1:num_busses] >= 0)
    @variable(model, VP[1:S] >= 0)

    M = 10000;

    #In bus data, a 3 indicates the slack bus, the connection to the grid
    slack_idx = findall(isequal(3), bus_data[:,3])
    non_slack_num = filter(x->x!=slack_idx, 1:num_busses)

    @constraint(model, [i in 1:num_busses], y[i] <= M)
    @NLconstraint(model, [i in 1:num_busses, s in 1:S], PG[i,s] - lf[s]*Pd[i] + Ploss[i,s] == sum((V[i,s]*V[j,s])*(G[i,j]*cos(theta[i,s]-theta[j,s])+B[i,j]*sin(theta[i,s]-theta[j,s])) for j in 1:num_busses))
    @constraint(model, [i in 1:num_busses, s in 1:S], Ploss[i,s] <= lf[s]*Pd[i])
    @NLconstraint(model, [i in 1:num_busses, s in 1:S], QG[i,s] - lf[s]*Qd[i] == sum((V[i,s]*V[j,s])*(G[i,j]*sin(theta[i,s]-theta[j,s])-B[i,j]*cos(theta[i,s]-theta[j,s])) for j in 1:num_busses))
    #This case has no flow limits
    #@NLconstraint(model, [i in 1:num_busses, j in 1:num_busses], I[i,j] == sqrt(G[i,j]^2+B[i,j]^2)*sqrt(V[i]^2+V[j]^2-2*V[i]*V[j]*cos(theta[j]-theta[i])))
    #When using capacity constraint sqrt(Pg^2+Qg^2) <= y, becomes infeasible
    #@constraint(model, [i in 1:num_busses], PG[i]+QG[i] <= y[i])
    @NLconstraint(model, [i in 1:num_busses, s in 1:S], (PG[i,s]^2+QG[i,s]^2)^(1/2) <= cf[s]*y[i])
    #This case has no flow limits
    #@constraint(model, [i in 1:num_busses, j in 1:num_busses] I[i,j] <= Imax[i,j])
    @constraint(model, [i in non_slack_num, s in 1:S], VMin[i] <= V[i,s] <= VMax[i])
    #@constraint(model, V[1] == 0)
    #@constraint(model, theta[1] == 0)
    @constraint(model,[s in 1:S], VP[s] == sum(V[i,s]*lf[s]*Pd[i] for i in 1:num_busses))
    @constraint(model, [i in 1:num_busses, s in 1:S],  -pi/2 <= theta[i,s] <= pi/2 )

    #NREL's SAM DATA default costs for photovoltaic residential setting
    c_var = 2.76;

    pi_s = 1/S;
    @objective(model, Min, sum(c_var*y[i] for i in 1:num_busses) +
                            beta*pi_s*sum(VP[s] for s in 1:S) +
                            gamma*pi_s*sum(Ploss[i,s] for i in 1:num_busses, s in 1:S))

    optimize!(model)

    return objective_value(model), JuMP.value.(y)
end