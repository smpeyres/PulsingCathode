"""
General function for parsing frequency, duty cycle, set current, and instance
from a single filename.

Examples:
1kHz_50%_5.7mA.jpg -> 1.0e3 Hz, 50%, 5.7 mA, first instance
600hz_50%_6.5mA.jpg -> 6.0e2 Hz, 50%, 6.5 mA, first instance
9kHz_20%_9.3mA_2.jpg -> 9.0e3 Hz, 20%, 9.3 mA, second instance
3mA_25per_500Hz_30Mar2026.jpg -> 5.0e2 Hz, 20%, 3.0 mA, first instance
9kHz_7.5%_7_8mA.csv -> 9.0e3 Hz, 7.5%, 7.8 mA, first instance
7khz_2.5%_6.5ma0.csv -> 7.0e3 Hz, 2.5%, 6.5 mA, first instance

imports:
re
pathlib
├─ TEST_CASES = [(name, expected), ...]        ← the table from last time
├─ def parse_name(name) -> dict                ← the function
├─ def run_tests(): ...                        ← assert loop over TEST_CASES
└─ if __name__ == "__main__": run_tests()
"""

import re
from pathlib import Path

# Patterns - independent of filename input
freq_pattern = re.compile(r"(\d+(?:\.\d+)?)(k?)hz", re.IGNORECASE) 
duty_pattern = re.compile(r"(\d+(?:\.\d+)?)(?:%|per)", re.IGNORECASE)
current_pattern = re.compile(r"(\d+)(?:\.|_)?(\d+)?ma0?(?![a-z])", re.IGNORECASE)
instance_pattern = re.compile(r"_(\d+)$") # must be at end of string 

def filename_parse(filename):

    file_path = Path(filename)
    file_stem = file_path.stem

    # Find frequency pattern 
    freq_found = freq_pattern.search(file_stem)

    # Extract frequency value if present
    if freq_found is not None:
        # print(f"Found frequency, unformatted: {freq_found.group(0)}")
        if freq_found.group(2): # if k is present -> an empty string is "falsy"
            freq = float(freq_found.group(1))*1000
            # print(f"Extracted frequency, Hz: {freq}")
        else:
            freq = float(freq_found.group(1))
            # print(f"Extracted frequency, Hz: {freq}")
    else:
        freq = float("nan")
        # print("No frequency found.")

    # Find the duty cycle pattern
    duty_found = duty_pattern.search(file_stem)

    # Extract duty cycle value if present
    if duty_found is not None:
        # print(f"Found duty cycle, unformatted: {duty_found.group(0)}")
        duty = float(duty_found.group(1))
        # print(f"Extracted duty cycle, %: {duty}")
    else:
        duty = float("nan")
        # print("No duty cycle found.")

    # Find the current pattern
    current_found = current_pattern.search(file_stem)

    # Extract set current if present
    if current_found is not None:
        # print(f"Found set current, unformatted: {current_found.group(0)}")
        part_pre = current_found.group(1) # get pre-decimal part
        if current_found.group(2): # if a decimal exists
            part_dec = current_found.group(2)
            current_string = part_pre + "." + part_dec
            current = float(current_string)
            # print(f"Extracted set current, mA: {current}")
        else:
            current = float(part_pre)
            # print(f"Extracted set current, mA: {current}")
    else:
        current = float("nan")
        # print("No set current found.")

    # Find the instance pattern
    instance_found = instance_pattern.search(file_stem)

    # Extract instance if present, set to 1 otherwise
    if instance_found is None:
        instance = 1
        # print(f"No instance provided. Assuming to be first instance.")
    elif int(instance_found.group(1)) == 0:
        instance = float("nan")
    else:
        instance = int(instance_found.group(1))
        # print(f"Instance of this condition: {instance}")

    parameter_dict = dict([("freq_hz", freq), ("duty_%", duty), ("current_ma", current), ("instance_#", instance)]) 

    return parameter_dict


