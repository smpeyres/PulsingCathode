"""Interactive image processing and Gaussian plasma-profile fitting."""

import re
import os
import sys
from datetime import datetime
from pathlib import Path
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from scipy.optimize import curve_fit
from skimage.color import rgb2gray
from skimage.exposure import rescale_intensity


IMAGE_DIRECTORY = Path(__file__).resolve().parent / "15Sep2026new"

TUBE_DIAMETER_MM = 6.35
MASTER_RESULTS_PATH = (
    Path(__file__).resolve().parent.parent / "MasterDataFiles" / "pulsed_image_data.csv"
)
RESULT_COLUMNS = [
    "Image Date",
    "Image Filename",
    "Frequency (Hz)",
    "Duty Cycle (%)",
    "Set Current (mA)",
    "Discharge Height (mm)",
    "Area (mm^2)",
    "Area Margin (mm^2)",
]


def parse_image_metadata(image_path: Path):
    """Parse date and pulse metadata from the imaging path/filename."""
    date_text = image_path.parent.name
    match = re.search(r"(\d{1,2}[A-Za-z]{3}\d{4})", date_text)
    if match:
        parsed_date = datetime.strptime(match.group(1), "%d%b%Y").strftime("%Y-%m-%d")
    else:
        parsed_date = datetime.now().strftime("%Y-%m-%d")

    stem = image_path.stem
    parts = stem.split("_")

    frequency_hz = None
    duty_cycle = None
    current_ma = None

    for part in parts:
        if part.endswith("kHz"):
            frequency_hz = float(part[:-3]) * 1_000
        elif part.endswith("Hz"):
            frequency_hz = float(part[:-2])
        elif part.endswith("%"):
            duty_cycle = float(part[:-1])
        elif part.endswith("mA"):
            current_ma = float(part[:-2])

    return parsed_date, image_path.name, frequency_hz, duty_cycle, current_ma


def save_results(date, image_filename, frequency, duty_cycle, set_current, discharge_height, area, area_margin):
    """Append results to the master CSV, replacing any duplicate date/filename record."""
    MASTER_RESULTS_PATH.parent.mkdir(parents=True, exist_ok=True)

    if MASTER_RESULTS_PATH.exists():
        results = pd.read_csv(MASTER_RESULTS_PATH)
    else:
        results = pd.DataFrame(columns=RESULT_COLUMNS)

    record = {
        "Image Date": date,
        "Image Filename": image_filename,
        "Frequency (Hz)": frequency,
        "Duty Cycle (%)": duty_cycle,
        "Set Current (mA)": set_current,
        "Discharge Height (mm)": discharge_height,
        "Area (mm^2)": area,
        "Area Margin (mm^2)": area_margin,
    }

    if "Date" in results.columns and "Image Filename" in results.columns:
        duplicate_mask = (
            results["Date"].astype(str).str.strip().eq(str(date))
            & results["Image Filename"].astype(str).str.strip().eq(str(image_filename))
        )
        if duplicate_mask.any():
            results = results.loc[~duplicate_mask].copy()

    results = pd.concat([results, pd.DataFrame([record], columns=RESULT_COLUMNS)], ignore_index=True)
    results.to_csv(MASTER_RESULTS_PATH, index=False)


IMAGE_FILES = sorted(
    path
    for path in IMAGE_DIRECTORY.iterdir()
    if path.is_file() and path.suffix.lower() in {".jpg", ".jpeg", ".png", ".tif", ".tiff"}
)
if not IMAGE_FILES:
    raise FileNotFoundError(f"No supported images found in {IMAGE_DIRECTORY}")

# The process is restarted after each image so the existing interactive
# analysis remains unchanged while images are handled sequentially.
try:
    image_index = int(os.environ.get("PULSING_IMAGE_INDEX", "0"))
except ValueError as exc:
    raise ValueError("Invalid image index in PULSING_IMAGE_INDEX.") from exc

if not 0 <= image_index < len(IMAGE_FILES):
    raise ValueError(f"Image index must be between 0 and {len(IMAGE_FILES) - 1}.")


def restart_current_image_on_error(exc_type, exc_value, exc_traceback):
    """Restart the current image so a failed analysis can be retried."""
    if issubclass(exc_type, KeyboardInterrupt):
        sys.__excepthook__(exc_type, exc_value, exc_traceback)
        return

    sys.__excepthook__(exc_type, exc_value, exc_traceback)
    print(
        f"Analysis failed for {IMAGE_FILES[image_index].name}; "
        "restarting the current image."
    )
    os.environ["PULSING_IMAGE_INDEX"] = str(image_index)
    os.execv(sys.executable, [sys.executable, str(Path(__file__).resolve())])


sys.excepthook = restart_current_image_on_error

IMAGE_PATH = IMAGE_FILES[image_index]
print(
    f"Analyzing image {image_index + 1}/{len(IMAGE_FILES)}: "
    f"{IMAGE_PATH.name}"
)

def wait_for_user():
    """Close the current figure when the user clicks anywhere in it."""
    figure = plt.gcf()

    def close_on_click(_event):
        plt.close(figure)

    figure.canvas.mpl_connect("button_press_event", close_on_click)
    plt.show(block=False)
    while plt.fignum_exists(figure.number):
        plt.pause(0.1)
    plt.close("all")

def gaussian(x, amplitude, center, stddev):
    return amplitude * np.exp(-(x-center)**2 / (2 * stddev**2))

def gaussian_with_background(x, a1, b1, c1, d1, e1,
                             amplitude, center, stddev):
    background = a1 + b1 * x + c1 * x**2 + d1 * x**3 + e1 * x**4
    return background + gaussian(x, amplitude, center, stddev)

# Load image
rgb_image = plt.imread(IMAGE_PATH)

# Calculate length per pixel
plt.figure()
plt.imshow(rgb_image)
plt.title("Select the left and right edges of the tube")
left_edge, right_edge = plt.ginput(2)
plt.close()

if left_edge[0] > right_edge[0]:
    left_edge, right_edge = right_edge, left_edge

pixel_diameter = abs(right_edge[0] - left_edge[0])
mm_per_pixel = TUBE_DIAMETER_MM / pixel_diameter

print(f"Conversion factor: {mm_per_pixel:.6g} mm/pixel")

plt.figure()
plt.imshow(rgb_image)
plt.plot(
    [left_edge[0], right_edge[0]],
    [left_edge[1], right_edge[1]],
    "r-",
    linewidth=2,
)
plt.plot(
    [left_edge[0], right_edge[0]],
    [left_edge[1], left_edge[1]],
    "r--",
    linewidth=2,
)
plt.title(f"Conversion factor: {mm_per_pixel:.6g} mm/pixel")
wait_for_user()

# Calculate discharge height
plt.figure()
plt.imshow(rgb_image)
plt.title("Select the top and bottom of discharge")
top_point, bottom_point = plt.ginput(2)
plt.close()

if top_point[1] > bottom_point[1]:
    top_point, bottom_point = bottom_point, top_point

pixel_height = abs(bottom_point[1] - top_point[1])
discharge_height = np.round(pixel_height * mm_per_pixel, 3)

print(f"Discharge height: {discharge_height:.6g} mm")

plt.figure()
plt.imshow(rgb_image)
plt.plot(
    [top_point[0], bottom_point[0]],
    [top_point[1], bottom_point[1]],
    "r-",
    linewidth=2,
)
plt.plot(
    [top_point[0], top_point[0]],
    [top_point[1], bottom_point[1]],
    "r--",
    linewidth=2,
)
plt.title(f"Discharge height: {discharge_height:.6g} mm")
wait_for_user()

# Select ROI
plt.figure()
plt.imshow(rgb_image)
plt.title("Select two opposite corners of the plasma ROI")
corner1, corner2 = plt.ginput(2)
plt.close()

x_min = max(0, int(np.floor(min(corner1[0], corner2[0]))))
x_max = min(rgb_image.shape[1], int(np.ceil(max(corner1[0], corner2[0]))))
y_min = max(0, int(np.floor(min(corner1[1], corner2[1]))))
y_max = min(rgb_image.shape[0], int(np.ceil(max(corner1[1], corner2[1]))))

cropped_image = rgb_image[y_min:y_max, x_min:x_max]

if cropped_image.size == 0:
    raise ValueError("The selected ROI must have non-zero width and height.")

plt.figure()
plt.imshow(cropped_image)
plt.title("Cropped ROI")
wait_for_user()

# Convert to grayscale and rescale.  Normalize explicitly before calling
# skimage so invalid, integer, or alpha-channel image data cannot reach its
# RGB matrix multiplication.
cropped_image = np.asarray(cropped_image)
if cropped_image.ndim == 3:
    if cropped_image.shape[2] < 3:
        raise ValueError("The selected ROI has fewer than three color channels.")
    cropped_rgb = cropped_image[..., :3].astype(np.float64, copy=False)
    finite_pixels = cropped_rgb[np.isfinite(cropped_rgb)]
    if finite_pixels.size == 0:
        raise ValueError("The selected ROI contains no finite pixel values.")
    image_min = finite_pixels.min()
    image_max = finite_pixels.max()
    if image_max > image_min:
        cropped_rgb = (cropped_rgb - image_min) / (image_max - image_min)
    else:
        cropped_rgb = np.zeros_like(cropped_rgb)
    cropped_rgb = np.nan_to_num(
        cropped_rgb, nan=0.0, posinf=1.0, neginf=0.0
    )
    cropped_gray = rgb2gray(cropped_rgb)
elif cropped_image.ndim == 2:
    cropped_gray = cropped_image.astype(np.float64, copy=False)
else:
    raise ValueError("The selected ROI has an unsupported image shape.")

cropped_gray = np.nan_to_num(cropped_gray, nan=0.0, posinf=0.0, neginf=0.0)

rescaled_gray = rescale_intensity(
    cropped_gray.astype(float),
    in_range="image",
    out_range=(0.0, 1.0),
)

plt.figure()
plt.imshow(rescaled_gray, cmap="gray")
plt.title("Cropped ROI in rescaled grayscale")
wait_for_user()

# Calculate centroid
rows, cols = rescaled_gray.shape
total_mass = np.sum(rescaled_gray)

if not np.isfinite(total_mass) or total_mass <= 0:
    raise ValueError("The selected ROI has no usable intensity.")

x_pixels = np.arange(1, cols + 1)
y_pixels = np.arange(1, rows + 1)

centroid_x = np.sum(np.sum(rescaled_gray, axis=0) * x_pixels) / total_mass
centroid_y = np.sum(np.sum(rescaled_gray, axis=1) * y_pixels) / total_mass

plt.figure()
plt.imshow(rescaled_gray, cmap="gray")
plt.scatter(centroid_x - 1, centroid_y - 1, s=100, c="red")
plt.title(f"Centroid: ({centroid_x:.3f}, {centroid_y:.3f})")
wait_for_user()

# Extract the row nearest the centroid
centroid_col = int(round(centroid_x)) - 1
centroid_row = int(round(centroid_y)) - 1
centroid_row = np.clip(centroid_row, 0, rows - 1)

row_luminance = rescaled_gray[centroid_row, :]
num_pixels = len(row_luminance)

x_data = mm_per_pixel * np.linspace(
    -round(num_pixels / 2),
    round(num_pixels / 2),
    num_pixels,
)

# Initial Gaussian fit
gaussian_initial_guess = [
    np.max(row_luminance) - np.min(row_luminance),
    x_data[np.argmax(row_luminance)],
    max((x_data[-1] - x_data[0]) / 6, 1e-6),
]

gaussian_params, _ = curve_fit(
    gaussian,
    x_data,
    row_luminance,
    p0=gaussian_initial_guess,
    bounds=([-np.inf, -np.inf, 1e-12], np.inf),
    maxfev=100000,
)

# Gaussian plus fourth-degree polynomial background
background_initial = [
    np.min(row_luminance),
    0,
    0,
    0,
    0,
]

full_initial_guess = background_initial + list(gaussian_params)

fit_params, covariance = curve_fit(
    gaussian_with_background,
    x_data,
    row_luminance,
    p0=full_initial_guess,
    bounds=(
        [-np.inf] * 7 + [1e-12],
        [np.inf] * 8,
    ),
    maxfev=100000,
)

fit_values = gaussian_with_background(x_data, *fit_params)

plt.figure()
plt.plot(x_data, row_luminance, "bo", markersize=3, label="Data")
plt.plot(x_data, fit_values, "r-", linewidth=2, label="Fit")
plt.xlabel("Position (mm)")
plt.ylabel("Intensity")
plt.legend()
wait_for_user()

print(len(x_data))

# Calculate area from the fitted Gaussian -> using std dev as radius
stddev = fit_params[7]
area = np.round(np.pi * stddev**2, 4)
print(f"Area: {area:.6g} mm^2")

# Calculate error margin in area using propagation of uncertainty
# Using 95% confidence interval
stddev_margin = np.sqrt(covariance[7, 7]) * 1.96  # 95% confidence interval
area_margin = np.round(2 * np.pi * stddev * stddev_margin, 4) # dA = 2 * pi * r * dr
print(f"Area error margin (95% CI): {area_margin:.6g} mm^2")

# Save results to a .csv file using pandas
# Open masterfile: ../MasterDataFiles/pulsed_image_data.csv
# Append the results to the end of the file, replace if date + filename already exists
# Fields:
# Date, Image Filename, Frequency, Duty Cycle, Set Current, Discharge Height, Area, Area Margin
date, image_filename, frequency, duty_cycle, set_current = parse_image_metadata(IMAGE_PATH)
save_results(
    date=date,
    image_filename=image_filename,
    frequency=frequency,
    duty_cycle=duty_cycle,
    set_current=set_current,
    discharge_height=discharge_height,
    area=area,
    area_margin=area_margin,
)
print(f"Results saved to {MASTER_RESULTS_PATH}")

if image_index + 1 < len(IMAGE_FILES):
    repeat_selection = input(
        "Repeat analysis for this image? [Y]es/[N]ext: "
    ).strip().lower()
    if repeat_selection not in {"y", "n"}:
        raise ValueError("Please enter Y to repeat or N to continue.")
else:
    print("All images have been analyzed.")
    raise SystemExit(0)

next_index = image_index if repeat_selection == "y" else image_index + 1
os.environ["PULSING_IMAGE_INDEX"] = str(next_index)
os.execv(sys.executable, [sys.executable, str(Path(__file__).resolve())])

 