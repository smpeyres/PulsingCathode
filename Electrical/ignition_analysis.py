import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# Import giant .csv file -> 1,000,000 points!
df = pd.read_csv("09_17/7khz_2.5%_6.6ma.csv", header=0)
print(f"Shape of imported data: {df.shape}")

# Set resistances external to cell, Ohms
ballast_res = 20e3
shunt_res = 100e3

# Set t_on -> later this can be pulled from the file name
duty_per = 2.5
freq = 7.0e3
on_time = duty_per/(freq*100)

# Get time series:
time_raw = df["Time(s)"].to_numpy() # unused but leaving for now
true_time_res = (time_raw[-1] - time_raw[0]) / (len(df) - 1)
time_vals = np.arange(len(df)) * true_time_res

# Calculate number of steps for on-time -> useful for edge filtering later
on_steps = round(on_time/true_time_res)

# Get all channel voltages
CH1_vals = df["CH1(V)"].to_numpy()
CH2_vals = df["CH2(V)"].to_numpy()
CH3_vals = df["CH3(V)"].to_numpy()

# Convert to physical voltages, V
TTL_voltage = CH3_vals
shunt_voltage = CH1_vals
cell_voltage = CH2_vals - shunt_voltage

# Calculate shunt current, A
shunt_current = shunt_voltage/shunt_res

# Calculate source voltage
source_voltage = cell_voltage + shunt_current*(ballast_res + shunt_res)

# Find the on segments of the source voltage
on_treshold_frac = 0.01
on_mask = source_voltage < on_treshold_frac*np.min(source_voltage)

fig1, ax = plt.subplots()
ax.scatter(time_vals, source_voltage*1e-3, s=1,label="w/out Mask")
ax.scatter(time_vals[on_mask], source_voltage[on_mask]*1e-3, s=1,color='r', label="w/ Mask")
ax.set_xlabel("Time (s)")
ax.set_ylabel("Source Voltage (kV)")
plt.legend()
plt.savefig("source_voltage_masked.png",dpi=600)

# Cast on_mask into int
on_int = on_mask.astype(int)
edges = np.diff(on_int)
starts = np.flatnonzero(edges == 1) + 1 
ends = np.flatnonzero(edges == -1)
keep = (ends - starts) > on_steps // 10
starts, ends = starts[keep], ends[keep]
print(starts)
print(ends)

fig2, ax = plt.subplots()
ax.scatter(time_vals, source_voltage*1e-3, s=1,label="w/out Mask")
ax.scatter(time_vals[on_mask], source_voltage[on_mask]*1e-3, s=1,color='r', label="w/ Mask")
ax.set_xlabel("Time (s)")
ax.set_ylabel("Source Voltage (kV)")
ax.set_xlim(left=2e-4, right=3e-4)
plt.legend()
plt.savefig("source_voltage_masked_zoom.png",dpi=600)