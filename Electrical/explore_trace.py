# Exploring oscilloscope traces               
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# Import giant .csv file -> 1,000,000 points!
df = pd.read_csv("30Mar2026/500Hz_25%_3mA.csv", header=0)
print(f"Shape of imported data: {df.shape}")
print(f"Columns of .csv file: {df.columns}")
print(f"Data types in dataframe: {df.dtypes}")

"""
pathlib.Path and a loop over Path("./30Mar2026").glob("*.csv")
function explore_trace(path) — actually, why not do that now?
Wrap what you have in a function that takes a path and returns the DataFrame, 
then call it at the bottom.
"""

# Calculation of discrete time differences
time_diff = df["Time(s)"].diff()
print(f"Minimum discrete difference of time: {time_diff.min()}. Should be zero.")
print(f"Maximum discrete different of time: {time_diff.max():.2e}")
# print(time_diff.median())

# Plot CH3 voltage vs time
time_vals = df["Time(s)"].to_numpy()
time_vals = time_vals - np.min(time_vals) # Set smallest time to zero
CH3_vals = df["CH3(V)"].to_numpy()

# Create on_mask -> where CH3(V) < 0.5 V
on_mask = np.where(CH3_vals < 0.5, 1.0, 0)
on_mask_bool = np.where(CH3_vals < 0.5, True, False)
actual_duty = np.mean(on_mask) # Should be very close to 25%!
print(f"Actual duty cycle: {100*actual_duty} %")

fig, ax = plt.subplots()
ax.plot(time_vals, CH3_vals, label="CH(3) Signal")
# ax.scatter(time_vals, CH3_vals, s=1)
ax.scatter(time_vals, on_mask, s=1, color='r', label="On Mask")
ax.set_xlabel("Time (s)")
ax.set_ylabel("Voltage (V)")
ax.set_ylim(bottom=-1.25)
plt.legend()
plt.savefig("CH3_explore.png",dpi=600)

# Calculate current waveform from CH1
shunt = 100e3 # 100 kOhm => 100e3 Ohm
CH1_vals = df["CH1(V)"].to_numpy()
I_ma = (CH1_vals/shunt)*1e3 # note conversion from A = V/Ohm to mA
average_ma = np.mean(I_ma)
print(f"Average current across waveform w/out correction: {np.round(average_ma,6)} mA")

masked_I_ma = np.multiply(I_ma, on_mask)
masked_average_ma = np.mean(masked_I_ma)
print(f"Average current across waveform w/ mask applied: {np.round(masked_average_ma,6)} mA")

# Plot current waveform
fig2, ax = plt.subplots()
ax.plot(time_vals, I_ma, label="w/out Mask")
ax.plot(time_vals, masked_I_ma, color='r', label="w/ Mask")
ax.set_xlabel("Time (s)")
ax.set_ylabel("Shunt Current (mA)")
ax.set_ylim(bottom=-15)
plt.legend()
plt.savefig("current_explore.png",dpi=600)

# Calculate peak current
peak_I_ma = I_ma[on_mask_bool]
peak_avg_ma = np.mean(peak_I_ma)
peak_std_ma = np.std(peak_I_ma)
print(f"Average peak current: {np.round(peak_avg_ma,6)} mA")
print(f"Standard dev. of peak current: {np.round(peak_std_ma,6)} mA")

# Grid check
print(f"All possible values of current: {np.unique(np.round(I_ma, 6))} mA")

