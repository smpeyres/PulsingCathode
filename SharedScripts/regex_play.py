import re

name = "_3.5ma0"

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
current_pattern = re.compile(r"(\d+)(?:\.|_)?(\d+)?ma(0?)", re.IGNORECASE)
current_found = current_pattern.search(name)

# Extract set current if present
if current_found is n

print(current_found.group(0))
print(current_found.group(1))
print(current_found.group(2))
print(current_found.group(3))