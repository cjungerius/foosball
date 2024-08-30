from trueskill import Rating, TrueSkill
import pandas as pd
import matplotlib.pyplot as plt

# Load the CSV file
df = pd.read_csv('foosball.csv')

env = TrueSkill(draw_probability=0)

# Create player skill trackers
players = {}
for player in pd.concat([df['red_1'], df['red_2'], df['yellow_1'], df['yellow_2']]).unique():
    players[player] = Rating()

# Process each game and update player ratings
for _, row in df.iterrows():
    red_team = (players[row['red_1']], players[row['red_2']])
    yellow_team = (players[row['yellow_1']], players[row['yellow_2']])
    goal_diff = row['diff']

    if goal_diff > 0:
        red_team, yellow_team = env.rate([red_team, yellow_team])
    else:
        yellow_team, red_team = env.rate([yellow_team, red_team])

    players[row['red_1']], players[row['red_2']] = red_team
    players[row['yellow_1']], players[row['yellow_2']] = yellow_team

print("Final skill ratings:")
for player, rating in players.items():
    print(f"Player: {player}, Skill Rating: {rating.mu:.2f}, Uncertainty: {rating.sigma:.2f}")

# Calculate skill ratings and uncertainty
skill_ratings = [rating.mu for rating in players.values()]
uncertainty = [rating.sigma for rating in players.values()]

# Calculate conservative skill estimates
conservative_skill_estimates = [rating.mu - 3 * rating.sigma for rating in players.values()]

# Create a dictionary of players and their conservative skill estimates
player_skill_estimates = dict(zip(players.keys(), conservative_skill_estimates))

# Sort players by conservative skill estimate
sorted_players = sorted(player_skill_estimates.items(), key=lambda x: x[1])

# Get the sorted player names and conservative skill estimates
player_names = [player for player, _ in sorted_players]
sorted_skill_estimates = [estimate for _, estimate in sorted_players]

# Get the sorted skill ratings and uncertainty
sorted_skill_ratings = [players[player].mu for player in player_names]
sorted_uncertainty = [players[player].sigma for player in player_names]

# Create a horizontal plot
plt.figure(figsize=(10, 6))

# Plot skill ratings with uncertainty as error bars
plt.errorbar(sorted_skill_ratings, range(len(sorted_players)), xerr=sorted_uncertainty, fmt='o', label='Skill Rating')

# Plot conservative skill estimates as separate points
plt.scatter(sorted_skill_estimates, range(len(sorted_players)), color='red', label='Conservative Skill Estimate')

plt.yticks(range(len(sorted_players)), player_names)
plt.xlabel('Skill Rating / Conservative Skill Estimate')
plt.title('Player Skill Ratings, Uncertainty, and Conservative Skill Estimates')
plt.legend()

# Show the plot
plt.tight_layout()
plt.show()