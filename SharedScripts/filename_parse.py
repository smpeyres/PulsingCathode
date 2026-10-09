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

main function: filename_parse(filename)

TEST_CASES = [(name, expected dict)]

test function: run_tests()

if __name__ == "__main__": run_tests()
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
        if freq_found.group(2): # if k is present -> an empty string is "falsy"
            freq = float(freq_found.group(1))*1000
        else:
            freq = float(freq_found.group(1))
    else:
        freq = None

    # Find the duty cycle pattern
    duty_found = duty_pattern.search(file_stem)

    # Extract duty cycle value if present
    if duty_found is not None:
        duty = float(duty_found.group(1))
    else:
        duty = None

    # Find the current pattern
    current_found = current_pattern.search(file_stem)

    # Extract set current if present
    if current_found is not None:
        part_pre = current_found.group(1) # get pre-decimal part
        if current_found.group(2): # if a decimal exists
            part_dec = current_found.group(2)
            current_string = part_pre + "." + part_dec
            current = float(current_string)
        else:
            current = float(part_pre)
    else:
        current = None

    # Find the instance pattern
    instance_found = instance_pattern.search(file_stem)

    # Extract instance if present, set to 1 otherwise
    if instance_found is None:
        instance = 1
    elif int(instance_found.group(1)) == 0:
        instance = None
    else:
        instance = int(instance_found.group(1))

    parameter_dict = dict([("freq_Hz", freq), ("duty_%", duty), ("set_current_mA", current), ("instance_#", instance)]) 

    return parameter_dict

TEST_CASES = [
    ("500Hz_25%_3mA.csv", {"freq_Hz": 500.0, "duty_%": 25.0, "set_current_mA": 3.0, "instance_#": 1}),
    ("9kHz_10%_8.5mA_2.csv", {"freq_Hz": 9000.0, "duty_%": 10.0, "set_current_mA": 8.5, "instance_#": 2}),
    ("30March2026.jpg", {"freq_Hz": None, "duty_%": None, "set_current_mA": None, "instance_#": 1}),
    ("9.5kHz_2.5%_8.7mA.csv", {"freq_Hz": 9500.0, "duty_%": 2.5, "set_current_mA": 8.7, "instance_#": 1}),
    ("2khz_10%_3.5mA.csv", {"freq_Hz": 2000.0, "duty_%": 10, "set_current_mA": 3.5, "instance_#": 1}),
    ("3mA_25per_500Hz_30March2026.jpg", {"freq_Hz": 500.0, "duty_%": 25, "set_current_mA": 3.0, "instance_#": 1}),
    ("7khz_2.5%_6.5ma0.csv", {"freq_Hz": 7000.0, "duty_%": 2.5, "set_current_mA": 6.5, "instance_#": 1}),
]

def run_tests():
    passed = 0
    failed = 0
    number_tests = len(TEST_CASES)
    for name, expected in TEST_CASES:
        actual = filename_parse(name)
        if actual == expected:
            print("PASS")
            passed +=1
        else:
            print("FAIL")
            print(f"Expected dict: {expected}")
            print(f"Actual dict: {actual}")
            failed +=1
    print(f"{passed}/{number_tests} passed, {failed}/{number_tests} failed")
    return

if __name__ == "__main__":
    run_tests()    