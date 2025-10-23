function calculate_rolling_volatility(log_returns::TimeArray, window::Int=20)
    return moving(std, log_returns, window)
end

function create_summary_statistics(ta::TimeArray)

    data_matrix = values(ta) 
    data_vector = data_matrix[:, 1]

    clean_data = filter(!isnan, data_vector)

    stats = Dict(
        "N" => length(clean_data),
        "Mean" => mean(clean_data),
        "Std Dev" => std(clean_data),
        "Min" => minimum(clean_data),
        "Max" => maximum(clean_data),
        "Median" => median(clean_data),
        "Skewness" => skewness(clean_data),
        "Kurtosis" => kurtosis(clean_data) + 3 
    )
    

    df = DataFrame(Statistics = collect(keys(stats)), Value = collect(values(stats)))

    df[2:end, :Value] = round.(df[2:end, :Value], digits=4)
    
    return df
end