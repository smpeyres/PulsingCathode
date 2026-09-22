# -*- coding: utf-8 -*-
import numpy as np
import datetime
from scipy import stats

# --- Start of Input ---

# set measurement date
date = datetime.date(2026, 9, 2)

# measured std NaCl concentrations and measured voltages
std_concs = [0.1, 1, 5, 10] # mM
std_volts = [267, 210, 165.5, 148.3] # mV

# check solutions: NaClO4 blank and initial NaClAc
blank_NaClAc_volts = 232 # mV @ 50 mM, 150 mM NaClO4

# sample names, mesaured voltages, average currents
sample_names = ['18DCA', '16DCA']
sample_volts = [202, 191] # mV
# sample_avg_current = to be obtained from the metadata!!! Is metadata the right word?

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

