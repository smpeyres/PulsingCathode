import numpy as np
from analyze_waveform import analyze_waveform
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "SharedScripts"))
from filename_parse import filename_parse

def batch_analyze_waveform(folder, collection_date):
    """For each waveform CSV in folder: filename metadata + computed scalars.
    Returns a list of row dicts (your batch_parse pattern)."""
    # Start with empty array -> will be fed into pd.DataFrame later
    rows = []
    # one file at time in directed folder
    for item in Path(folder).iterdir():
        # if something other than file (such as folder), skip
        if not item.is_file():
            continue
        # if item is not .csv, skip
        if item.suffix not in (".csv"):  
            continue
        # get the file name
        row = {}
        row["source_file"] = item.name
        # construct row with collection date
        row["collection_date"] = collection_date
        # use filename_parse to get parameters from name
        row.update(filename_parse(item.name))
        # use analyze_waveform.py to get computed scalars from waveform
        row.update(analyze_waveform(item))
        # Append dict as row to rows
        rows.append(row)
    return rows