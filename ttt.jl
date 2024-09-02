using CSV, TrueSkillThroughTime, DataFrames

# Load data
data = CSV.read("foosball.csv", DataFrame)

composition = Vector{Vector{Vector{String}}}() # Vector of teams

# iterate over rows of dataframe
for row in eachrow(data)
    # Get the player objects for each player in the row
    red = [row.red_1, row.red_2]
    yellow = [row.yellow_1, row.yellow_2]
    teams = row.diff > 0 ? [red, yellow] : [yellow, red]
    push!(composition, teams)
end

h = History(composition, gamma=0.1)

convergence(h)

lc = learning_curves(h)

agents = collect(keys(h.agents)) # select some agents
agents = ["chris", "kirsten", "cate", "nico"]

# Plot all the learning_curves
pp = plot(xlabel="t", ylabel="mu", title="Learning Curves")
for (i, agent) in enumerate(agents)
    t = [v[1] for v in lc[agent] ]
    mu = [v[2].mu for v in lc[agent] ]
    sigma = [v[2].sigma for v in lc[agent] ]
    plot!(t, mu, color=i, label=agent)
    plot!(t, mu.+sigma, fillrange=mu.-sigma, alpha=0.2,color=i, label=false)
end
display(pp)


for agent in agents
    mu = lc[agent][end][2].mu
    sigma = lc[agent][end][2].sigma
    println("Agent: $agent, mu: $mu, sigma: $sigma")
end
