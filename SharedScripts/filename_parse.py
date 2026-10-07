"""
General function for parsing frequency, duty cycle, set current, and instance
from filename in a given directory.

Examples:
1kHz_50%_5.7mA.jpg -> 1.0e3 Hz, 0.5, 5.7 mA, first instance
600hz_50%_6.5mA.jpg -> 6.0e2 Hz, 0.5, 6.5 mA, first instance
9kHz_20%_9.3mA_2.jpg -> 9.0e3 Hz, 0.2, 9.3 mA, second instance
3mA_25per_500Hz_30Mar2026.jpg -> 5.0e2 Hz, 0.2, 3.0 mA, first instance
9kHz_7.5%_7_8mA.csv -> 9.0e3 Hz, 0.075, 7.8 mA, first instance
7khz_2.5%_6.5ma0.csv -> 7.0e3 Hz, 0.025, 6.5 mA, first instance

imports:
re
pathlib
├─ TEST_CASES = [(name, expected), ...]        ← the table from last time
├─ def parse_name(name) -> dict                ← the function
├─ def run_tests(): ...                        ← assert loop over TEST_CASES
└─ if __name__ == "__main__": run_tests()
"""

import re
import pathlib