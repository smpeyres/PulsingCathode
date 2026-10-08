import pandas as pd
import numpy as np
# import sys
# from pathlib import Path
# sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "SharedScripts"))
# from filename_parse import filename_parse

def analyze_waveform(csv_path):
    """ Read one RIGOL waveform CSV, compute quantities, and return a dict of scalars"""
    
    # import csv as dataframe
    df = pd.read_csv(csv_path, header=0)
    
    # Calculation of minimum discrete time differences
    time_diff_min = df["Time(s)"].diff().min()
    if time_diff_min < 0.0:
        time_ok = False
    else:
        time_ok = True
    
    # Define on mask as when CH3 is less than 0.5 V
    CH3_vals = df["CH3(V)"].to_numpy()
    on_mask = CH3_vals < 0.5
    
    # Guard clause
    if not on_mask.any():
        return {"time_monotonic": time_ok, "duty_%": None, "peak_current_mA": None, "peak_current_std_mA": None, "average_current_mA": None}
    
   
    # Calculate duty cycle
    duty = np.mean(on_mask*np.ones_like(CH3_vals))
    
    # Calculate current waveform from CH1 -> negative current as convention
    shunt_res = 100e3 # 100 kOhm => 100e3 Ohm
    CH1_vals = df["CH1(V)"].to_numpy()
    I_shunt = (CH1_vals/shunt_res)*1e3 # mA
    
    # Calculate "masked" shunt current -> positive stuff is not "real"
    I_shunt_masked = I_shunt*on_mask
    I_shunt_on = I_shunt_masked[on_mask]
    I_shunt_on_mean = np.mean(I_shunt_on)
    I_shunt_on_std = np.std(I_shunt_on) # quantization "staircase", not noise -> but still useful to define spread of peak.
    I_shunt_masked_mean = I_shunt_on_mean*duty
    
    return {"time_monotonic": time_ok, "duty_%": duty*100, "peak_current_mA": I_shunt_on_mean, "peak_current_std_mA": I_shunt_on_std, "average_current_mA": I_shunt_masked_mean}
    
    
if __name__ == "__main__":
    analyze_waveform("30Mar2026/1kHz_5%_5mA.csv")
