# shot AQ00 - Jan 09, 2026

import plotly.graph_objects as go
import pandas as pd

data = pd.DataFrame({
    'I':         [10,  10,  10,  10,  10,  20,  20,  20,  20,  20,  5,   5,   5,   5,   5,   5,   5,   5,   5,   10,  10,  10,  10,  10,  10,  20,  20,  20,  20,  20,  20,  5,   5,   5,   5,   10,  10,  10,  10,  10,  5,   5,   5,   5,   20,  20,  20,  20,  20],
    'D':         [50,  25,  10,  5,   1,   50,  25,  10,  5,   1,   50,  75,  25,  90,  10,  5,   1,   0.5, 0.1, 50,  25,  10,  5,   1,   0.5, 50,  25,  10,  5,   1,   0.5, 25,  10,  5,   1,   50,  25,  10,  5,   1,   50,  25,  10,  5,   50,  25,  10,  5,   1],
    'f':         [1e3, 1e3, 1e3, 1e3, 1e3, 1e3, 1e3, 1e3, 1e3, 1e3, 1e3, 1e3, 1e3, 1e3, 1e3, 1e3, 1e3, 1e3, 1e3, 1e4, 1e4, 1e4, 1e4, 1e4, 1e4, 1e4, 1e4, 1e4, 1e4, 1e4, 1e4, 1e4, 1e4, 1e4, 1e4, 1e2, 1e2, 1e2, 1e2, 1e2, 1e2, 1e2, 1e2, 1e2, 1e2, 1e2, 1e2, 1e2, 1e2],
    'stability': [0,   0,   1,   1,   1,   0,   1,   1,   1,   0,   0,   0,   0,   0,   0,   1,   1,   1,   0,   0,   0,   1,   1,   1,   0,   1,   1,   1,   1,   0,   0,   0,   0,   0,   0,   0,   0,   0,   1,   0,   0,   0,   0,   0,   0,   0,   0,   1,   0],
})

stable = data[data['stability'] == 1]
unstable = data[data['stability'] == 0]

fig = go.Figure()
fig.add_trace(go.Scatter3d(
    x=stable['I'], y=stable['D'], z=stable['f'],
    mode='markers', marker=dict(size=5, color='green'),
    name='Stable'))
fig.add_trace(go.Scatter3d(
    x=unstable['I'], y=unstable['D'], z=unstable['f'],
    mode='markers', marker=dict(size=5, color='red', symbol='x'),
    name='Unstable'))

from scipy.spatial import ConvexHull

# Get coordinates of stable points
points = stable[['I', 'D', 'f']].values

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
            title='Current (A)',  # your label
            type='linear'  # or 'log'
        ),
        yaxis=dict(
            title='Duty Cycle',
            type='log'  # or 'log'
        ),
        zaxis=dict(
            title='Frequency (Hz)',
            type='log'  # or 'linear'
        )
    )
)


fig.write_html("stability_plot_AQ00.html")