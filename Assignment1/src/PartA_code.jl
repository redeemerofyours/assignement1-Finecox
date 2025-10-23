
## region important packages and initialize DrWatson project 


import Pkg
# Pkg.add("DrWatson")
using DrWatson
# initialize_project("Assignment1"; authors = "Jáchym Janů, Bohdan Hukovych")



@quickactivate 

# Pkg.add(["Distributions", "Plots", "ForwardDiff" , "Optim" , "MarketData" , "YFinance" , "ARCHModels", "CSV", "DataFrames", "RollingFunctions", "StatsBase", "Statistics", "IJulia"])
# Pkg.add(["TimeSeries", "CSVFiles", "StatsPlots", "Flux"])
# Pkg.instantiate()

Pkg.status()

using IJulia
# IJulia.installkernel("Julia")
using Distributions
using Plots; gr()
using ForwardDiff
using Optim
using MarketData
using YFinance
using ARCHModels
using CSV
using DataFrames
using Plots.PlotMeasures
using RollingFunctions
using StatsBase
using Statistics
using TimeSeries
using CSVFiles
using StatsPlots
using Flux



include(srcdir("functions.jl"))

## endregion
## region load data


# Load the VTYX data
file_path = datadir("exp_raw", "VTYX.txt")
column_names = [
    :Date, 
    :Time, 
    :Open, 
    :High, 
    :Low, 
    :Close, 
    :Volume
]

VTYX_data = CSV.read(
    file_path, 
    DataFrame, 
    delim=',',            
    ignorerepeated=true,
    header=column_names 
)


println(first(VTYX_data, 5))
println(last(VTYX_data, 5))


begining = DateTime(2021, 10, 21)
finish = DateTime(2025, 01, 08)

VTYX_data_01 = yahoo(:VTYX, YahooOpt(period1 = begining, period2 = finish, interval = "1d"))

head(VTYX_data_01, 5)
tail(VTYX_data_01, 5)


## endregion
## region calculate log returns and plot them

AdjClose = VTYX_data_01[:AdjClose]
dates = timestamp(AdjClose)
log_returns = log.(AdjClose ./ lag(AdjClose))

p_ret = plot(log_returns, 
    title = "Log Returns VTYX - AdjClose to AdjClose",
    label = "Log Returns",
    xlabel = "Date",
    ylabel = "Log Return",
    legend = :bottomright,
    xticks = (dates[1:40:end], dates[1:40:end]),
    xrotation = 50,
    ylims = (-2, 1),
    size = (800,600),
    bottom_margin = 20px,
    left_margin = 20px,
    top_margin = 20px,
    color = :darkgreen
     )


# plots_path = plotsdir("vtyx_log_returns_graf.png")
# safesave(plots_path, p_ret)



## endregion
## region calculate rolling volatility and plot it




rolling_std =  calculate_rolling_volatility(log_returns, 5)
current_name = colnames(rolling_std)[1]
TimeSeries.rename!(rolling_std, current_name => :Std_log_returns)
head(rolling_std, 5)


p_vol = plot(rolling_std, 
    title = "Weekly Volatility of Log Returns VTYX - AdjClose to AdjClose",
    label = "Volatility",
    xlabel = "Date",
    ylabel = "Volatility",
    legend = :bottomright,
    xticks = (dates[1:40:end], dates[1:40:end]),
    xrotation = 50,
    ylims = (-0.3, 1),
    size = (800,600),
    bottom_margin = 20px,
    left_margin = 20px,
    top_margin = 20px,
    color = :darkblue
     )



# plots_path = plotsdir("vtyx_log_returns_volatility_graf.png")
# safesave(plots_path, p_vol)


## endregion
## region rolling volatility and its summary statistics

summary_table = create_summary_statistics(log_returns)


# filepath = datadir("exp_pro", "log_returns_summary.csv")
# safesave(filepath, summary_table)


## endregion
## region histogram of log returns with normal distribution fit

μ = mean(log_returns)
σ = std(log_returns)
μ = values(μ)[1]
σ = values(σ)[1]

min_val = μ - 20*σ
max_val = μ + 7*σ

fitted_dist = Distributions.Normal(μ,σ)

tick_locations = range(min_val, max_val, length=10)
tick_labels = [string(round(loc, sigdigits=3)) for loc in tick_locations]

hist = histogram(
    log_returns, 
    bins = :auto,                
    normalize = :pdf,            
    title = "Histogram of Daily Log Returns - Close to Close",
    xlabel = "Log Returns",
    ylabel = "pdf",
    label = "Histogram of Log Returns",
    legend = false,
    fillalpha = 0.7,
    xticks = (tick_locations, tick_labels),
    xrotation = 90,
    bottom_margin = 20px,
    left_margin = 20px,
    top_margin = 20px           
    )
    plot!(
    fitted_dist, 
    linewidth = 2, 
    linecolor = :red, 
    xlims = extrema(log_returns),
    label = "Normal Distribution",
    legend = :left
)


# plots_path = plotsdir("vtyx_log_returns_log_returns_histogram.png")
# safesave(plots_path, hist)

## endregion
## region volatility ACF and PACF plots
pure_data = values(log_returns)
max_lag = 20

acf_results = autocor(values(log_returns), 1:max_lag) 
lags_x = 1:max_lag


N = length(values(log_returns))
ci = 1.96 / sqrt(N)


acf_plot = plot(
    lags_x, 
    acf_results, 
    seriestype = :bar,
    marker = (:circle, 3), 
    title = "ACF volatilitiy log returns",
    xlabel = "Lag",
    label = false,
    linewidth = 1.5,
    ylims = (-0.3, 1)
)
hline!([-ci, ci], line = (:dash, 1, :blue), label = "95% CI")

pacf_results = StatsBase.pacf(pure_data, 1:max_lag)
lags_x_pacf = 1:max_lag # Začínáme od lag 1

# PACF Plot
pacf_plot = plot(
    lags_x_pacf, 
    pacf_results, 
    seriestype = :bar,
    marker = (:circle, 3), 
    title = "PACF volatilitiy log returns",
    xlabel = "Lag",
    label = false,
    linewidth = 1.5,
    ylims = (-0.3, 1)
)
hline!([-ci, ci], line = (:dash, 1, :blue), label = false)


plot(acf_plot, pacf_plot, layout = (2, 1))
## endregion
## region GARCH model fitting


ARCHLMTest_results = ARCHModels.ARCHLMTest(values(log_returns), 1)

GARCH_model_1_1 = fit(GARCH{1, 1}, values(log_returns))
GARCH_model_2_1 = fit(GARCH{2, 1}, values(log_returns))
GARCH_model_1_2 = fit(GARCH{1, 2}, values(log_returns))
GARCH_model_2_2 = fit(GARCH{2, 2}, values(log_returns))



## endregion















println("PartA_code.jl executed successfully.")