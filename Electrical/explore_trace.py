# Exploring oscilloscope traces               
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# Import giant .csv file -> 1,000,000 points!
df = pd.read_csv("09_17/7khz_2.5%_6.6ma.csv", header=0)
print(f"Shape of imported data: {df.shape}")
print(f"Columns of .csv file: {df.columns}")
print(f"Data types in dataframe: {df.dtypes}")
print(df.head(2))

# Calculation of discrete time differences
time_diff = df["Time(s)"].diff()
print(f"Minimum discrete difference of time: {time_diff.min():.2e}. Should be zero.")
print(f"Maximum discrete different of time: {time_diff.max():.2e}")
# print(time_diff.median())

# Plot CH3 voltage vs time
time_vals = df["Time(s)"].to_numpy()
time_vals = time_vals - np.min(time_vals) # Set smallest time to zero
CH3_vals = df["CH3(V)"].to_numpy()

# Create on_mask -> where CH3(V) < 0.5 V
on_mask = CH3_vals < 0.5
actual_duty = np.mean(on_mask*np.ones_like(CH3_vals)) # Should be very close to 25%!
print(f"Actual duty cycle: {100*actual_duty} %")

fig, ax = plt.subplots()
ax.plot(time_vals, CH3_vals, label="CH(3) Signal")
ax.scatter(time_vals, on_mask*np.ones_like(CH3_vals), s=1, color='r', label="On Mask")
ax.set_xlabel("Time (s)")
ax.set_ylabel("Voltage (V)")
plt.legend()
plt.savefig("CH3_explore.png",dpi=600)

# Get high-voltage channels
CH1_vals = df["CH1(V)"].to_numpy() 
CH2_vals = df["CH2(V)"].to_numpy()

# Use to get voltage across shunt, cell
shunt_voltage = CH1_vals
cell_voltage = CH2_vals - shunt_voltage

# Plot voltages
fig2, ax = plt.subplots()
ax.scatter(time_vals, shunt_voltage*1e-3, s=1, label="Shunt Voltage")
ax.scatter(time_vals, cell_voltage*1e-3, s=1, label="Cell Voltage")
ax.set_xlabel("Time (s)")
ax.set_ylabel("Voltage (kV)")
plt.legend()
plt.savefig("voltage_explore.png",dpi=600)

# Plot voltages
fig3, ax = plt.subplots()
ax.scatter(time_vals, shunt_voltage*1e-3, s=1, label="Shunt Voltage")
ax.scatter(time_vals, cell_voltage*1e-3, s=1, label="Cell Voltage")
ax.set_xlabel("Time (s)")
ax.set_ylabel("Voltage (kV)")
ax.set_xlim(left=0.9e-4, right=1.5e-4)
plt.legend()
plt.savefig("voltage_explore_zoom.png",dpi=600)

"""
# Calculate current waveform from CH1
shunt_res = 100e3 # 100 kOhm => 100e3 Ohm
I_shunt = (shunt_voltage/shunt_res)*1e3 # mA
# Grid check
print(f"All possible values of current: {np.unique(np.round(I_shunt, 6))} mA")

I_shunt_mean = np.mean(I_shunt)
print(f"Average current across waveform w/out correction: {np.round(I_shunt_mean,6)} mA")

I_shunt_masked = I_shunt*on_mask

# Plot current waveform
fig2, ax = plt.subplots()
ax.plot(time_vals, I_shunt, label="w/out Mask")
ax.plot(time_vals, I_shunt_masked, color='r', label="w/ Mask")
ax.set_xlabel("Time (s)")
ax.set_ylabel("Shunt Current (mA)")
plt.legend()
plt.savefig("current_explore.png",dpi=600)

# Calculate peak current
I_shunt_on = I_shunt_masked[on_mask]
I_shunt_on_mean = np.mean(I_shunt_on)
I_shunt_on_std = np.std(I_shunt_on)
I_shunt_corrected_mean = I_shunt_on_mean*actual_duty
print(f"Average peak current: {I_shunt_on_mean:.6f} mA")
print(f"Standard dev. of peak current: {I_shunt_on_std:.6f} mA")
print(f"Average current across waveform w/ correction: {I_shunt_corrected_mean:.6f} mA")

# Plot current pulse - zoom
fig3, ax = plt.subplots()
ax.scatter(time_vals, I_shunt, s=1, label="w/out Mask")
ax.scatter(time_vals, I_shunt_masked, s=1, color='r', label="w/ Mask")
ax.set_xlabel("Time (s)")
ax.set_ylabel("Shunt Current (mA)")
ax.set_xlim(left=0.9e-4, right=1.5e-4)
plt.legend()
plt.savefig("current_explore_zoom.png",dpi=600)

# Plot CH2 - zoom
CH2_vals = df["CH2(V)"].to_numpy()
fig4, ax = plt.subplots()
ax.scatter(time_vals, CH2_vals, s=1)
ax.set_xlabel("Time (s)")
ax.set_ylabel("Cell Voltage (V)")
ax.set_xlim(left=0.9e-4, right=1.5e-4)
plt.legend()
plt.savefig("cell_voltage_zoomed.png",dpi=600)

"""