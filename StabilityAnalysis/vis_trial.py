import plotly.graph_objects as go

fig = go.Figure()
fig.add_trace(go.Scatter3d(
    x=stable['I'], y=stable['D'], z=stable['f'],
    mode='markers', marker=dict(size=5, color='green'),
    name='Stable'))
fig.add_trace(go.Scatter3d(
    x=unstable['I'], y=unstable['D'], z=unstable['f'],
    mode='markers', marker=dict(size=5, color='red', symbol='x'),
    name='Unstable'))
fig.show()