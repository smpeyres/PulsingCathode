import numpy as np
# Calculate minimum concentration for stable points
D_e = 4.9e-9 # m^2/s
k_2 = 5.5e6 # m^3/mol-s

k_s = 1.5e6 # m^3/mol-s
D_s = 1.1e-9 # m^2/s
F = 96485 # C/mol
A = 1e-7 # 0.1 mm^2 guess

# Sodium chloride - Brandon's data
# All 50% duty cycle for now
frequencies = [100, 500, 1000, 5000, 10000] # Hz
iPeaks = [4.8*2e-3, 5.0*2e-3, 5.2*2e-3, 6.5*2e-3, 6.7*2e-3] # A
duty_cycles = [0.5, 0.5, 0.5, 0.5, 0.5] # 50% duty cycle

for i in range(len(frequencies)):
    t_on = duty_cycles[i] / frequencies[i] # seconds
    k_r = (k_2**2*iPeaks[i]*iPeaks[i]/(A*A*F*F*D_e))**(1/3) # 1/s
    C_min = np.sqrt(t_on*4*D_s/np.pi)*iPeaks[i]/(F*A) + k_r/k_s # mol/m^3
    print(f"Frequency: {frequencies[i]} Hz, i_p: {iPeaks[i]*1e3:.2f} mA, Duty Cycle: {duty_cycles[i]*100:.0f}%, C_min: {C_min:.2e} mol/m^3")