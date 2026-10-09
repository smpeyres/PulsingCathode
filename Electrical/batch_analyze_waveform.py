import numpy as np
import pandas as pd # ?
from analyze_waveform import analyze_waveform
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "SharedScripts"))
from filename_parse import filename_parse

def batch_analyze_waveform(directory, date_of_analysis):
    """For each waveform CSV in directory: filename metadata + computed scalars.
    Returns a list of row dicts (your batch_parse pattern)."""
    return directory, date_of_analysis