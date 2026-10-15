import pandas as pd
import numpy as np
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "SharedScripts"))
from filename_parse import filename_parse

def analyze_waveform(csv_name):
    """ Read one RIGOL waveform CSV, compute quantities, and return a dict of scalars"""
    
    # import csv as dataframe
    df = pd.read_csv(csv_name, header=0)

    # Extract quantities from csv_name
    parameters = filename_parse(csv_name)
    frequency = parameters['freq_Hz']
    duty_per = parameters['duty_%']

    # Calculate period, pulse width
    period = 1/frequency
    pulse_width = period*duty_per/100

    # Extract time values
    time_raw = df["Time(s)"].to_numpy()
    # True resolution =/= displayed resolution
    # Take total time / number of timesteps
    true_time_res = (time_raw[-1] - time_raw[0]) / (len(df) - 1) 
    # Make linear array with original length with true time resolution
    time_vals = np.arange(len(df)) * true_time_res

    # Calculate number of timesteps in a period
    num_steps_per_period = int(round(period/true_time_res))

    # Calculate number of whole periods in trace
    num_periods = int(time_vals[-1] // period)

    # Get voltage drop across downstream ballast 
    down_ballast_voltage = df["CH1(V)"].to_numpy()

    # Find the off states of the downstream ballast
    treshold_frac = 0.02
    off_mask = down_ballast_voltage > treshold_frac*np.min(down_ballast_voltage) 

    # Use off mask to calculate offset voltage
    offset_voltage = np.mean(down_ballast_voltage[off_mask])
    down_ballast_voltage_true = down_ballast_voltage - offset_voltage
    
    # Set downstream ballast resistance
    down_ballast_res = 100e3

    # Calculate instantaneous conduction current across downstream ballast
    cond_current_down_ballast = down_ballast_voltage_true/down_ballast_res

    # Calculate charge delivered across whole periods
    charge_total_whole_periods = np.trapezoid(cond_current_down_ballast[0:num_periods*num_steps_per_period], time_vals[0:num_periods*num_steps_per_period])

    # Calculate average charge delivered per period
    charge_per_period = charge_total_whole_periods/num_periods

    # Calculate ideal peak current
    ideal_peak_current = charge_per_period/pulse_width
    
    return {"charge_per_period_uC": charge_per_period/1e-6, "ideal_peak_current_mA": ideal_peak_current/1e-3}

if __name__ == "__main__":
    res = analyze_waveform("30Mar2026/1kHz_5%_5mA.csv")
    print(res)