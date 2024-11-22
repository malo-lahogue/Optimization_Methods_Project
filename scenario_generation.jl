using CSV, DataFrames, StatsBase, Distributions, Plots

function sample_load(season, hour)
    load_fits = CSV.read("DATA/load_fits.csv", DataFrame)
    first_row = load_fits[(load_fits.Season .== season) .&& (load_fits.Hour .== hour), :]
    best_model = first_row.Model[1]
    parameters = first_row.Parameters[1]



    # Generate a random value using the best fitted model
    if best_model == "LogNormal"
        μ = parse(Float64, match(r"μ=-([0-9.])", parameters).captures[1])
        σ = parse(Float64, match(r"σ=([0-9.]+)", parameters).captures[1])
        fit = LogNormal(μ, σ)
    elseif best_model == "Gamma"
        α = parse(Float64, match(r"α=([0-9.]+)", parameters).captures[1])
        θ = parse(Float64, match(r"θ=([0-9.]+)", parameters).captures[1])
        fit = Gamma(α, θ)
    elseif best_model == "Weibull"
        α = parse(Float64, match(r"α=([0-9.]+)", parameters).captures[1])
        θ = parse(Float64, match(r"θ=([0-9.]+)", parameters).captures[1])
        fit = Weibull(α, θ)
    elseif best_model == "Normal"
        μ = parse(Float64, match(r"μ=([0-9.]+)", parameters).captures[1])
        σ = parse(Float64, match(r"σ=([0-9.]+)", parameters).captures[1])
        fit = Normal(μ, σ)
    elseif best_model == "InverseGaussian"
        μ = parse(Float64, match(r"μ=([0-9.]+)", parameters).captures[1])
        λ = parse(Float64, match(r"λ=([0-9.]+)", parameters).captures[1])
        fit = InverseGaussian(μ, λ)
    else
        error("Unsupported model: $best_model")
    end

    # Generate a random value
    random_value = 2
    while random_value >1
        random_value = rand(fit)
    end


    return random_value
end


function sample_cf(season, hour)
    "randomly pick one historical point in the same season and hour
    (didn't succeed in fitting a distribution to the data)"
    cf_historical = CSV.read("DATA/Capacity_factor/capacity_factor.csv", DataFrame)


    cf_by_hour_season = cf_historical[(cf_historical[:, :hour] .== hour-1).&&(cf_historical[:, :season] .== season), :"Capacity factor"]


    return rand(cf_by_hour_season)
end