from filename_parse import filename_parse
from pathlib import Path

def batch_parse(folder):
    # start with empty array -> will be fed into pd.DataFrame later
    rows = []         
    # one file at time in directed folder                    
    for item in Path(folder).iterdir():
        # if something other than file (such as folder), skip
        if not item.is_file():
            continue
        # construct row dict from filename parser
        row = filename_parse(item.name)
        # Add new "column"/"key" with name of file 
        row["source_file"] = item.name
        # Append dict to rows to form new row
        rows.append(row)
    return rows