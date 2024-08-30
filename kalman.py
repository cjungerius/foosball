import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# Load the game data
df = pd.read_csv('foosball.csv')

# Mapping players to indices
players = pd.concat([df['red_1'], df['red_2'], df['yellow_1'], df['yellow_2']]).unique()
player_to_index = {player: i for i, player in enumerate(players)}
num_players = len(players)

# Adjusted Kalman filter parameters
initial_skill = 100
x = np.full((num_players, 1), initial_skill)
P = np.eye(num_players) * 10    # initial uncertainty
A = np.eye(num_players)
Q = np.eye(num_players) * .5    # Process noise
R = np.array([[.1]])          # Measurement noise

# Initialize skill history dictionary
rating_history = {player: [] for player in players}

# Kalman filter functions
def predict(A, x, P, Q):
    x_pred = A @ x
    P_pred = A @ P @ A.T + Q
    return x_pred, P_pred

def update(x_pred, P_pred, H, z, R):
    S = H @ P_pred @ H.T + R
    K = P_pred @ H.T @ np.linalg.inv(S)
    x_update = x_pred + K @ (z - H @ x_pred)
    P_update = (np.eye(len(x_pred)) - K @ H) @ P_pred
    return x_update, P_update

# Process each game and update rating history
for _, row in df.iterrows():
    red_team = [player_to_index[row['red_1']], player_to_index[row['red_2']]]
    yellow_team = [player_to_index[row['yellow_1']], player_to_index[row['yellow_2']]]
    goal_diff = row['diff']

    H = np.zeros((1, num_players))
    H[0, red_team] = 1
    H[0, yellow_team] = -1
    z = np.array([[goal_diff]])

    x_pred, P_pred = predict(A, x, P, Q)
    x, P = update(x_pred, P_pred, H, z, R)

    # Store the current skill rating for each player
    for player in players:
        rating_history[player].append(x[player_to_index[player]][0])

print("Final skill ratings and uncertainties:")
for player in players:
    skill_rating = x[player_to_index[player]][0]
    uncertainty = P[player_to_index[player], player_to_index[player]]
    print(f"Player: {player}, Skill Rating: {skill_rating:.2f}, Uncertainty: {uncertainty:.2f}")
