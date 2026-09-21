import scienceplots
from cycler import cycler
import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np

plt.style.use('./custom.mplstyle')

mpl.rcParams["text.usetex"] == True

x1 = [2, 4, 6]
y1 = [3.6, 5, 4.2]
x2 = [1, 3, 5]
y2 = [4.2, 1.0, 6.7]
yerr = [0.5, 0.6, 0.3]
fig, ax = plt.subplots()
ax.errorbar(x1, y1, yerr, fmt='o', markersize = 3, linewidth=1, capsize=2)
ax.errorbar(x2, y2, yerr, fmt='s', markersize = 3, linewidth=1, capsize=2)
plt.show()














# def model(x, p):
#     return x ** (2 * p + 1) / (1 + x ** (2 * p))

# pparam = dict(xlabel="Voltage (mV)", ylabel=r"Current ($\mu$A)")

# x = np.linspace(0.75, 1.25, 201)
# fig, ax = plt.subplots()
# for p in [10, 15, 20]:
#     ax.plot(x, model(x, p), label=p)
# ax.legend(title="Order")
# ax.set(**pparam)
# fig.savefig("fig01a.jpg", dpi=600)
# plt.show()
# plt.close()


# # Styles 'science', 'scatter'
# with plt.style.context(["./custom.mplstyle", "scatter"]):
#     fig, ax = plt.subplots(figsize=(4, 4))
#     ax.plot([-2, 2], [-2, 2], "k--")
#     ax.fill_between(
#         [-2, 2], [-2.2, 1.8], [-1.8, 2.2], color="dodgerblue", alpha=0.2, lw=0
#     )
#     for i in range(7):
#         x1 = np.random.normal(0, 0.5, 10)
#         y1 = x1 + np.random.normal(0, 0.2, 10)
#         ax.plot(x1, y1, label=r"$^\#${}".format(i + 1))
#     lgd = r"$\mathring{P}=\begin{cases}1&\text{if $\nu\geq0$}\\0&\text{if $\nu<0$}\end{cases}$"
#     ax.legend(title=lgd, loc=2, ncol=2)
#     xlbl = r"$\log_{10}\left(\frac{L_\mathrm{IR}}{\mathrm{L}_\odot}\right)$"
#     ylbl = r"$\log_{10}\left(\frac{L_\circledast}{\mathrm{L}_\odot}\right)$"
#     ax.set_xlabel(xlbl)
#     ax.set_ylabel(ylbl)
#     ax.set_xlim([-2, 2])
#     ax.set_ylim([-2, 2])
#     fig.savefig("fig03.jpg", dpi=300)
#     plt.close()