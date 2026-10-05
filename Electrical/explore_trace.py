# Exploring oscilloscope traces               
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# Import giant .csv file -> 1,000,000 points!
df = pd.read_csv("30Mar2026/500Hz_25%_3mA.csv", header=0)
print(df.shape)
print(df.columns)
print(df.dtypes)

"""
pathlib.Path and a loop over Path("./30Mar2026").glob("*.csv")
function explore_trace(path) — actually, why not do that now?
Wrap what you have in a function that takes a path and returns the DataFrame, 
then call it at the bottom.
"""

# Calculation of discrete time differences
time_diff = df["Time(s)"].diff()
print(time_diff.min())
print(time_diff.max())
print(time_diff.median())

# Plot CH3 voltage vs time
time_vals = df["Time(s)"].to_numpy()
time_vals = time_vals - np.min(time_vals) # Set smallest time to zero
CH3_vals = df["CH3(V)"].to_numpy()

fig, ax = plt.subplots()
ax.plot(time_vals, CH3_vals)
ax.set_xlabel("Time (s)")
ax.set_ylabel("Channel 3 Signal (V)")
plt.show()

# Calculate current waveform from CH1
shunt = 100e3 # 100 kOhm => 100e3 Ohm
CH1_vals = df["CH1(V)"].to_numpy()
I_ma = (CH1_vals/shunt)*1e3 # note conversion from A = V/Ohm to mA
average_ma = np.mean(I_ma)
print(average_ma)

# Plot current waveform
fig2, ax = plt.subplots()
ax.plot(time_vals, I_ma)
ax.set_xlabel("Time (s)")
ax.set_ylabel("Shunt Current (mA)")
plt.show()