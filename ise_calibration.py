import numpy as np
import pandas as pd
import datetime
from scipy import stats



# My thought at the moment:
# Create a seperate folder/directory called "ISE"
# In that folder, each experiment will have its own csv file.
# Easy to write to and read from.
# User (me) will input information in this script.
# Script will write to the csv file once analysis is complete.


# Items to store:
# Date of ISE measurement
# Standard NaCl concentrations and measured voltages
# What is best formating? 
# Should it be std #1 conc, std #1 voltage, std #2 conc, std #2 voltage, etc. 
# Or should it be a table with 2 columns and 4 rows? 
# I think the latter is better. But how to write this in one file?

# Blank NaClO4 and initial NaClAc voltages
# Sample names, measured voltages.
# Dilution factor
# Eventually, average currents and faradaic efficiency.
# Average current will need to be obtained from the 'master data file'. Is this the right word?
# Same sort of formatting question as above.

# This will need to be readable later with a for loop in order to extract the data for analysis.
# We will want to add the FE in particular to the 'master data file'.

# 'Master data file' will be a separate file that contains all the data from all the experiments. 
# It will be a csv file with columns for each piece of data and rows for each experiment. 
# This will allow for easy analysis and comparison of the data.



# --- Start of Input ---






# set measurement date
date = datetime.date(2026, 9, 3)

# Add this data to a dataframe to be appended to the Excel file
df = pd.DataFrame({
    'Date': [date]})

with pd.ExcelWriter('ExperimentLog.xlsx', engine='openpyxl', mode='a', if_sheet_exists='overlay') as writer:
    df.to_excel(writer, sheet_name="ISE Tracker", index=False)

## Write to an existing file if date does not already exist in the file, otherwise throw an error
if date in pd.read_excel('ExperimentLog.xlsx', sheet_name="ISE Tracker")['Date'].values:
    print(f"Date {date} already exists in the Excel file. Please choose a different date.")
else:
    with pd.ExcelWriter('ExperimentLog.xlsx', engine='openpyxl', mode='a', if_sheet_exists='overlay') as writer:
        df.to_excel(writer, sheet_name="ISE Tracker", index=False)







# measured std NaCl concentrations and measured voltages
std_concs = [0.1, 1, 5, 10] # mM
std_volts = [267, 210, 165.5, 148.3] # mV

# check solutions: NaClO4 blank and initial NaClAc
blank_NaClAc_volts = 232 # mV @ 50 mM, 150 mM NaClO4

# sample names, mesaured voltages, average currents
sample_names = ['18DCA', '16DCA']
sample_volts = [202, 191] # mV
# sample_avg_current = to be obtained from the 'master data file'

# set dilution factor
# ex: dilution = 2 if diluting 10 mL (200 mM IS) to 20 mL (100 mM IS) with DI.
dilution = 2

# --- End of Input ---


# --- Start of Calculator ---

# log10 concentrations
std_concs_log = np.log10(std_concs)

# linear regression
# y = mx + b
# y = ise voltage [mV]
# m = slope [mV/decade]
# x = log10 concentration [log10(mM)]
# b = intercept [mV]

res = stats.linregress(std_concs_log, std_volts)
print(f"R-squared: {res.rvalue**2:.6f}")
print(f"Slope: {res.slope:.6f} mV/decade")

# Show figure

# calculate sample Cl- concentrations in original sample pre-dilution
# x = (y-b)/m
sample_concs = dilution*(10**((sample_volts - res.intercept)/res.slope))

# calculate Cl- concentration in NaClAc
blank_NaClAc_conc = dilution*(10**((blank_NaClAc_volts - res.intercept)/res.slope))

# calculate change in concentration
sample_concs_change = sample_concs - blank_NaClAc_conc

# --- End of Calculator ---

