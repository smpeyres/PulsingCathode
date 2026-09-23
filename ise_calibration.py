import numpy as np
import pandas as pd
import datetime
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
std_concs = [0.1, 1, 5, 10] # mM
std_volts = [267, 210, 165.5, 148.3] # mV

# measured voltage for initial NaClAc
blank_NaClAc_volts = 232 # mV @ 50 mM, 150 mM NaClO4

# sample names and measured voltages
sample_names = ['18DCA', '16DCA', '17DCA']
sample_volts = [202, 191, 178.7] # mV

# set dilution factor
# ex: dilution = 2 if diluting 10 mL (200 mM IS) to 20 mL (100 mM IS) with DI.
dilution = 2

# --- End of User Input ---

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

# Make a dataframe to store the data, with indexes/rows with the standard numbers
df = pd.DataFrame({
    'Sample': [f'Std {i+1}' for i in range(num_stds)],
    'Concentration (mM)': std_concs,
    'Voltage (mV)': std_volts,
})

# 


# Write it all to a .csv file in the directed directory
# Need to implement the check for whether the file already exists.
with open(f'{data_dir}/{date}.csv', 'w') as file:
    file.write(f'Date: {date}\n')
    df.to_csv(file, index=False)








# # set measurement date
# date = datetime.date(2026, 9, 3)

# # Add this data to a dataframe to be appended to the Excel file
# df = pd.DataFrame({
#     'Date': [date]})

# with pd.ExcelWriter('ExperimentLog.xlsx', engine='openpyxl', mode='a', if_sheet_exists='overlay') as writer:
#     df.to_excel(writer, sheet_name="ISE Tracker", index=False)

# ## Write to an existing file if date does not already exist in the file, otherwise throw an error
# if date in pd.read_excel('ExperimentLog.xlsx', sheet_name="ISE Tracker")['Date'].values:
#     print(f"Date {date} already exists in the Excel file. Please choose a different date.")
# else:
#     with pd.ExcelWriter('ExperimentLog.xlsx', engine='openpyxl', mode='a', if_sheet_exists='overlay') as writer:
#         df.to_excel(writer, sheet_name="ISE Tracker", index=False)







# # measured std NaCl concentrations and measured voltages
# std_concs = [0.1, 1, 5, 10] # mM
# std_volts = [267, 210, 165.5, 148.3] # mV

# # check solutions: NaClO4 blank and initial NaClAc
# blank_NaClAc_volts = 232 # mV @ 50 mM, 150 mM NaClO4

# # sample names, mesaured voltages, average currents
# sample_names = ['18DCA', '16DCA']
# sample_volts = [202, 191] # mV
# # sample_avg_current = to be obtained from the 'master data file'

# # set dilution factor
# # ex: dilution = 2 if diluting 10 mL (200 mM IS) to 20 mL (100 mM IS) with DI.
# dilution = 2

# # --- End of Input ---


# # --- Start of Calculator ---

# # log10 concentrations
# std_concs_log = np.log10(std_concs)

# # linear regression
# # y = mx + b
# # y = ise voltage [mV]
# # m = slope [mV/decade]
# # x = log10 concentration [log10(mM)]
# # b = intercept [mV]

# res = stats.linregress(std_concs_log, std_volts)
# print(f"R-squared: {res.rvalue**2:.6f}")
# print(f"Slope: {res.slope:.6f} mV/decade")

# # Show figure

# # calculate sample Cl- concentrations in original sample pre-dilution
# # x = (y-b)/m
# sample_concs = dilution*(10**((sample_volts - res.intercept)/res.slope))

# # calculate Cl- concentration in NaClAc
# blank_NaClAc_conc = dilution*(10**((blank_NaClAc_volts - res.intercept)/res.slope))

# # calculate change in concentration
# sample_concs_change = sample_concs - blank_NaClAc_conc

# # --- End of Calculator ---

