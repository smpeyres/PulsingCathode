import numpy as np
import pandas as pd
import datetime
import os
from scipy import stats

# Revised thoughts on how to store data.
# Create a seperate folder/directory called "ISE" -> done. 
# In that folder, each experiment will have its own csv file.
# Easy to write to and read from.
# User (me) will input ISE information in this script.
# Script will write to a new csv file once analysis is complete.

# If a csv file already exists for that date,
# The script will first ask whether to overwrite the file or not.
# User provides y or n.
# If y, the script will overwrite the file.
# If n, the script will halt and ask the user to choose a different date.

# Structure of CSV file
# Header will include date, dilution factor as user-defined information
# Header will also include the slope, intercept, and R^2 value calculated.
# Data will be stored in a simple column and row format.
# Columns: Cl- concentration (mM), measured voltage (mV), and faradaic efficiency (%)

# Rows will be: std #1, ... std #N, init NaClAc, sample ID #1, ..., sample ID #N
# Concentration and voltage for standards are known and measured, respectively.
# For FE, standards will be left with NaN.
# Voltages for initial NaClAc, and samples are measured and concentrations are calculated.
# FE for initial NaClAc will be left with NaN.
# FE for samples will be calculated and stored in the file only if an average current is provided.

# For numbering of standards, 
# the number will be based on the number of concentrations reported in array.
# Exact ordering is not important for data storage, 
# just that std1 and std2 and so on have the right concentrations and voltages associated with them.
# For the samples, 
# the user will provide the sample names in an array and the measured voltages in a separate array.

# For average current, 
# the script will obtain the average current from the 'master data file' based on the sample name provided by the user.

# End of thoughts on how to store data.

# --- Start of User Input ---

# Identify directory to store data
data_dir = "./ISE"

# Identify relevant Master Data File
master_data_file = "./MasterDataFiles/DC_Ar_50mM.csv"

# set measurement date
date = datetime.date(2026, 9, 2) # testing date

# measured std NaCl concentrations and measured voltages
std_concs = np.array([0.1, 1, 5, 10]) # mM
std_volts = np.array([267, 210, 165.5, 148.3]) # mV

# measured voltage for initial NaClAc
blank_NaClAc_volts = 232 # mV @ 50 mM, 150 mM NaClO4

# sample names and measured voltages
sample_names = ['18DCA', '16DCA', '17DCA']
sample_volts = np.array([202, 191, 178.7]) # mV

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
master_df = pd.read_csv(master_data_file, header=1)  # Skip the first row which is just info

# Extract the average currents for the samples
sample_avg_currents = []
for name in sample_names:
    if name not in master_df['Sample ID'].values:
        raise ValueError(f"Sample name {name} not found in the master data file.") 
    else:
        sample_avg_currents.append(master_df.loc[master_df['Sample ID'] == name, 'Average Current (mA)'].values[0])

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
FE = np.round((sample_concs_change * vol_ml * 1e-6 * F) / (np.array(sample_avg_currents)*1e-3 * time_hrs * 3600) * 100 , 3) # %

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
output_file = f'{data_dir}/{date}.csv'
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

# --- End of Data Storage ---

