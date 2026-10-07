import re

name = "6.5ma0"

# Find frequency pattern
freq_pattern = re.compile(r"(\d+(?:\.\d+)?)(k?)hz", re.IGNORECASE) 
freq_found = freq_pattern.search(name)

# Extract frequency value if present
if freq_found is not None:
    print(f"Found frequency, unformatted: {freq_found.group(0)}")
    if freq_found.group(2): # if k is present -> an empty string is "falsy"
        freq = float(freq_found.group(1))*1000
        print(f"Extracted frequency, Hz: {freq}")
    else:
        freq = float(freq_found.group(1))
        print(f"Extracted frequency, Hz: {freq}")
else:
    freq = float("nan")
    print("No frequency found.")

# Find the duty cycle pattern
duty_pattern = re.compile(r"(\d+(?:\.\d+)?)(?:%|per)", re.IGNORECASE)
duty_found = duty_pattern.search(name)

# Extract duty cycle value if present
if duty_found is not None:
    print(f"Found duty cycle, unformatted: {duty_found.group(0)}")
    duty = duty_found.group(1)
    print(f"Extracted duty cycle, %: {duty}")
else:
    duty = float("nan")
    print("No duty cycle found.")

# Find the current pattern
current_pattern = re.compile(r"(\d+)(?:\.|_)?(\d+)?ma0?(?![a-z])", re.IGNORECASE)
current_found = current_pattern.search(name)

# Extract set current if present
if current_found is not None:
    print(f"Found set current, unformatted: {current_found.group(0)}")
    part_pre = current_found.group(1) # get pre-decimal part
    if current_found.group(2): # if a decimal exists
        part_dec = current_found.group(2)
        current_string = part_pre + "." + part_dec
        current = float(current_string)
        print(f"Extracted set current, mA: {current}")
    else:
        current = float(part_pre)
        print(f"Extracted set current, mA: {current}")
else:
    current = float("nan")
    print("No set current found.")