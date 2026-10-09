from analyze_waveform import analyze_waveform
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "SharedScripts"))
from filename_parse import filename_parse
import pandas as pd
from datetime import date

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
        if item.suffix != ".csv":  
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

def is_iso_date(entry):
    try:
        date.fromisoformat(str(entry))
        return True
    except ValueError:
        return False

def store_waveform_to_masterfile(rows, masterfile_path):
    """Merge rows into an existence masterfile at masterfile_path"""
    # turn filepath in path object
    master_path = Path(masterfile_path)

    # Make sure the masterfile exists
    if not master_path.exists():
        raise FileNotFoundError(f"Masterfile path not found: {masterfile_path}")

    # Get construct data frame from csv
    master_df = pd.read_csv(masterfile_path)

    # Make sure it has all required columns
    required = ["collection_date", "freq_Hz", "duty_%", "set_current_mA", "instance_#"]
    missing = [col for col in required if col not in master_df.columns]
    if missing:
        raise KeyError(f"Masterfile missing required columns: {missing}")

    # Make sure dates in master_df are properly formatted
    master_dates = master_df['collection_date']
    bad_master_dates = [entry for entry in master_dates if not is_iso_date(entry)]
    if bad_master_dates:
        raise ValueError(f"Non-ISO dates in masterfile: {bad_master_dates}")

    # turn rows from batch_analyze_waveform into dataframe
    waveform_df = pd.DataFrame(rows)

    # Make sure dates in waveform_df are properly formatted
    waveform_dates = waveform_df['collection_date']
    bad_waveform_dates = [entry for entry in waveform_dates if not is_iso_date(entry)]
    if bad_waveform_dates:
        raise ValueError(f"Non-ISO dates in waveform data: {bad_waveform_dates}")

    # Merge dataframe together
    master_df = master_df.merge(waveform_df,
                      on=["collection_date", "freq_Hz", "duty_%", "set_current_mA","instance_#"],
                      how="outer",
                      suffixes=("", "_new"))

    # Fill in the na's
    computed_cols = ["source_file", "time_monotonic", "measured_duty_%",
                 "peak_current_mA", "peak_current_std_mA", "average_current_mA"]

    for col in computed_cols:
        new_col = col + "_new"
        if new_col in master_df.columns:
            master_df[col] = master_df[new_col].fillna(master_df[col])
            master_df = master_df.drop(columns=new_col)

    return master_df

if __name__ == "__main__":          # ← the guard, bottom of the file
    directory = "./09_28"
    collection_date = "2026-09-28"
    masterfile = "../MasterDataFiles/sample_pulsed.csv"
    rows = batch_analyze_waveform(directory, collection_date)   # your real folder path
    df = store_waveform_to_masterfile(rows, masterfile)
    print(df)
    print(df.dtypes)
    df.to_csv(masterfile, index=False)