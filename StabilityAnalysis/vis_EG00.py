# shot EG00 - Jan 09, 2026

import plotly.graph_objects as go
import pandas as pd

data = pd.DataFrame({
    'I':         [10,  10,  10,  10,  10,  10,  10,  10,  10,  10,  10,  10,  10,  10,  10,  10,  10,  10,  10,  10,  10,  10,  10,  10,  10,  10,  20,  20,  20,  20,  20,  20,  20,  20,  20,  20,  5,   5,   5,   5,   5],
    'D':         [50,  25,  10,  5,   1,   0.1, 85,  50,  10,  5,   1,   0.1, 50,  25,  10,  5,   50,  25,  10,  5,   1,   50,  25,  10,  5,   1,   50,  25,  10,  5,   1,   50,  25,  10,  5,   1,   5,   10,  10,  10,  5],
    'f':         [1e3, 1e3, 1e3, 1e3, 1e3, 1e3, 1e4, 1e4, 1e4, 1e4, 1e4, 1e4, 1e2, 1e2, 1e2, 1e2, 2e2, 2e2, 2e2, 2e2, 2e2, 5e2, 5e2, 5e2, 5e2, 5e2, 1e4, 1e4, 1e4, 1e4, 1e4, 1e3, 1e3, 1e3, 1e3, 1e3, 1e4, 1e4, 1e1, 1e2, 1e1],
    'stability': [0,   0,   1,   1,   1,   0,   0,   0,   1,   1,   1,   0,   0,   0,   1,   0,   0,   0,   0,   1,   0,   0,   0,   0,   1,   0,   1,   1,   1,   1,   1,   0,   1,   1,   1,   0,   0,   0,   0,   0,   0],
})

data['i_p'] = 100 * data['I'] / data['D']
data['t_on'] = 0.01 * data['D'] / data['f']

stable = data[data['stability'] == 1]
unstable = data[data['stability'] == 0]

fig = go.Figure()
fig.add_trace(go.Scatter3d(
    x=stable['i_p'], y=stable['D'], z=stable['t_on'],
    mode='markers', marker=dict(size=5, color='green'),
    name='Stable'))
fig.add_trace(go.Scatter3d(
    x=unstable['i_p'], y=unstable['D'], z=unstable['t_on'],
    mode='markers', marker=dict(size=5, color='red', symbol='x'),
    name='Unstable'))

from scipy.spatial import ConvexHull

# Get coordinates of stable points
points = stable[['i_p', 'D', 't_on']].values

hull = ConvexHull(points)

# Add hull as mesh
fig.add_trace(go.Mesh3d(
    x=points[:, 0],
    y=points[:, 1],
    z=points[:, 2],
    i=hull.simplices[:, 0],
    j=hull.simplices[:, 1],
    k=hull.simplices[:, 2],
    color='lightgreen',
    opacity=0.3,
    name='Stable hull'
))


# Update axes
fig.update_layout(
    scene=dict(
        xaxis=dict(
            title='Peak Current (mA)',  # your label
            type='log'  # or 'log'
        ),
        yaxis=dict(
            title='Duty Cycle (%)',
            type='log'  # or 'log'
        ),
        zaxis=dict(
            title='On time (s)',
            type='log'  # or 'linear'
        )
    )
)


fig.write_html("stability_plot_EG00.html")

# Check data to see if any points are stable with D > 50%
high_duty_stable = data[(data['stability'] == 1) & (data['D'] > 50)]
print(f"\nStable points with D > 50%:")
print(high_duty_stable[['I', 'D', 'f', 'i_p', 't_on']])
print(f"\nTotal: {len(high_duty_stable)} stable points with duty cycle > 50%")

# Calculate minimum concentration for stable points
k_r = 1.2e6 # 1/s
k_s = 1.5e6 # m^3/mol-s
D_s = 1.1e-9 # m^2/s
F = 96485 # C/mol
A = 1e-6 # 1 mm^2 guess

import numpy as np
stable['C_min'] = np.sqrt(stable['t_on']*4/(np.pi*D_s))*(stable['i_p']*1e-3/(F*A)) + k_r/k_s # mol/m^3
print(f"\nMinimum concentration for stable points:")
print(stable[['D', 'f', 'i_p', 'C_min']])
