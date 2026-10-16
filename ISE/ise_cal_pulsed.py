import numpy as np
import pandas as pd
import datetime
import os
from scipy import stats

# --- Start of User Input ---

# Identify relevant Master Data File
master_data_file = "../MasterDataFiles/Ar_50mM_pulsed.csv"

# set measurement date
date = datetime.date(2026, 9, 19) # testing date

# measured std NaCl concentrations and measured voltages
std_concs = np.array([0.1, 1, 5, 10]) # mM
std_volts = np.array([255, 202, 161.4, 144.1]) # mV

# measured voltage for initial NaClAc
blank_NaClAc_volts = 222 # mV @ 50 mM, 150 mM NaClO4

# sample names and measured voltages
sample_names = ['2.5_1']
sample_volts = np.array([195.9]) # mV

# set dilution factor
# ex: dilution = 2 if diluting 10 mL (200 mM IS) to 20 mL (100 mM IS) with DI.
dilution = 2.0

# Below are inputs that change very little and therefore are currently hardcoded. 
# volume
vol_ml = 20.0 # mL
# time
time_hrs = 1.0 # hour

# --- End of User Input ---

# --- Start of Calculator ---

# Get average currents for the samples from the master data file
# Read the master data file into a pandas dataframe
master_df = pd.read_csv(master_data_file, header=0)  # Skip the first row which is just info

# Extract: frequencies, charge per period
sample_frequency = []
sample_charge_per_period = []
for name in sample_names:
    if name not in master_df['sample_ID'].values:
        raise ValueError(f"Sample name {name} not found in the master data file.") 
    else:
        sample_frequency.append(master_df.loc[master_df['sample_ID'] == name, 'freq_Hz'].values[0])
        sample_charge_per_period.append(master_df.loc[master_df['sample_ID'] == name, 'charge_per_period_uC'].values[0])
# flip sign, put into Coulombs
sample_charge_per_period = np.multiply(sample_charge_per_period,-1e-6)

# Calculate number of periods in total time
sample_num_periods = np.multiply(sample_frequency, time_hrs*3600)

# Calculate total charge delivered
sample_total_charge = sample_charge_per_period*sample_num_periods

# Count number of standards and make sure the lengths of the arrays match
num_stds = len(std_concs)
if num_stds != len(std_volts):
    raise ValueError("The number of standard concentrations and voltages must match.")

# Count number of measured samples to make sure lengths of arrays match
num_samples = len(sample_names)
if num_samples != len(sample_volts):
    raise ValueError("The number of sample names and voltages must match.")

# log10 concentrations
std_concs_log = np.log10(std_concs)

# linear regression
# y = mx + b
# y = ise voltage [mV]
# m = slope [mV/decade]
# x = log10 concentration [log10(mM)]
# b = intercept [mV]
res = stats.linregress(std_concs_log, std_volts)

# Print result for quick user check
print(f"R-squared: {res.rvalue**2:.6f}")
print(f"Slope: {res.slope:.6f} mV/decade")

# Calculate absolute percent errors - not stored, just for user check
calc_std_concs = 10**((std_volts - res.intercept)/res.slope)
abs_per_error = np.abs( (std_concs - calc_std_concs)/std_concs )*100
# Print to user up to 2 decimal points
with np.printoptions(precision=2):
    print(f"Abs. % Errors: {abs_per_error}")
# Recommendation: replace anything ≥10%

# Calculate Cl- concentration in NaClAc
blank_NaClAc_conc = np.round(dilution*(10**((blank_NaClAc_volts - res.intercept)/res.slope)), 3)

# Calculate sample Cl- concentrations in original sample pre-dilution
sample_concs = np.round(dilution*(10**((sample_volts - res.intercept)/res.slope)), 3)

# Calculate change in concentration for each sample relative to the blank NaClAc
sample_concs_change = sample_concs - blank_NaClAc_conc

# Calculate faradaic efficiency (FE) for each sample
# FE = (change in concentration * volume * F) / (average current * time)
# F = Faraday's constant = 96485 C/mol
F = 96485 # C/mol
FE = np.round((sample_concs_change * vol_ml * 1e-6 * F) / (np.array(sample_total_charge)) * 100 , 3) # %

# --- End of Calculator ---

# --- Start of Data Storage ---

# Make a dataframe to store the data, with indexes/rows with the standard numbers
df = pd.DataFrame({
    # 'Sample': [f'Std {i+1}' for i in range(num_stds)] + ['NaClAc'] + sample_names,
    'Sample' : [f'Std {i+1}' for i in range(num_stds)] + ['NaClAc'] + sample_names,
    'Concentration (mM)': np.concatenate((std_concs, [blank_NaClAc_conc], sample_concs)),
    'Voltage (mV)': np.concatenate((std_volts, [blank_NaClAc_volts], sample_volts)),
    'Faradaic Efficiency (%)': np.concatenate((np.zeros(num_stds), [0], FE))
})

# Check to see if desired output file already exists
output_file = f'{date}.csv'
if os.path.exists(output_file):
    overwrite = input(
        f'{output_file} already exists. Overwrite? (Y/N): '
    ).strip().upper()
    if overwrite != 'Y':
        print('Halting. Please change the date and run the script again.')
        raise SystemExit

# Write df to a .csv file in the directed directory
with open(output_file, 'w') as file:
    file.write(f'Date: {date}\n')
    df.to_csv(file, index=False)

"""
# Store data of ISE measurement and FE of each sample to master data file
# Master data file location: ./MasterDataFiles/DC_Ar_50mM.csv
# Append the data to the master data file
# Preserve the first informational header row before reading and rewriting the dataframe.
with open(master_data_file, 'r') as file:
    master_header = file.readline()

master_df = pd.read_csv(master_data_file, header=1)  # Skip the first row which is just info
for i, name in enumerate(sample_names):
    master_df.loc[master_df['Sample ID'] == name, 'ISE Date'] = date
    master_df.loc[master_df['Sample ID'] == name, 'Faradaic Efficiency (%)'] = FE[i]

with open(master_data_file, 'w') as file:
    file.write(master_header)
    master_df.to_csv(file, index=False)
"""

# --- End of Data Storage ---

