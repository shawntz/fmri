#!/usr/bin/env python3

import argparse
import os
import json
import csv
import re
from glob import glob

def load_config(config_path):
    with open(config_path, "r") as f:
        return json.load(f)

def get_expected_series_map(config):
    mapping = {}
    for seq_type, props in config["default_sequences"].items():
        for sn in props["series_numbers"]:
            mapping[sn] = {
                "sequence_type": seq_type,
                "description": props.get("description", ""),
                "series_description_pattern": props.get("series_description_pattern"),
                "filename_template": props.get("filename_template"),
                "series_description": props.get("series_description"),
                "required": props.get("required", False)
            }
    return mapping

def run_qc(input_dir, config_path, output_csv):
    config = load_config(config_path)
    expected_by_series_number = get_expected_series_map(config)

    bids_paths = ['func', 'anat', 'fmap']

    records = []

    for bids_type in bids_paths:
        for nii_path in glob(os.path.join(input_dir, bids_type, "*.nii.gz")):
            base = os.path.basename(nii_path).replace(".nii.gz", "")
            json_path = os.path.join(input_dir, base + ".json")

            row = {
                "Filename": base,
                "AcquisitionNumber": None,
                "SeriesDescription": None,
                "MatchedSequence": "FALSE",
                "SequenceType": "",
                "Match": "FALSE",
                "RunFromDescription": "",
                "RunMatchToFilename": "N/A"
            }

            if not os.path.exists(json_path):
                row["SeriesDescription"] = "Missing JSON"
                records.append(row)
                continue

            with open(json_path, "r") as f:
                metadata = json.load(f)

            acq = metadata.get("AcquisitionNumber")
            desc = metadata.get("SeriesDescription")

            row["AcquisitionNumber"] = acq
            row["SeriesDescription"] = desc

            if acq not in expected_by_series_number:
                records.append(row)
                continue

            expected = expected_by_series_number[acq]
            row["SequenceType"] = expected["sequence_type"]
            row["MatchedSequence"] = "TRUE"

            pattern = expected.get("series_description_pattern")
            template = expected.get("filename_template")

            if pattern:
                match = re.search(pattern, desc or "")
                if match and "run" in match.groupdict():
                    run_num = int(match.group("run"))
                    run_str = f"run-{run_num:02d}"
                    row["RunFromDescription"] = run_str

                    if template:
                        expected_fragment = template.format(run=run_num)
                        row["RunMatchToFilename"] = "TRUE" if expected_fragment in base else "FALSE"
                        row["Match"] = "TRUE" if row["RunMatchToFilename"] == "TRUE" else "FALSE"
                    else:
                        row["Match"] = "TRUE"
                else:
                    row["RunMatchToFilename"] = "FALSE"
                    row["Match"] = "FALSE"
            else:
                expected_desc = expected.get("series_description")
                if expected_desc:
                    row["Match"] = "TRUE" if desc == expected_desc else "FALSE"
                else:
                    row["Match"] = "TRUE"

            records.append(row)

    # Write CSV
    with open(output_csv, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=records[0].keys())
        writer.writeheader()
        writer.writerows(records)

    print(f"✅ QC summary written to: {output_csv}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run metadata QC for converted NIfTI files")
    parser.add_argument("--subid", required=True, help="Subject ID (e.g., 001)")
    parser.add_argument("--project_dir", required=True, help="Base project directory")
    parser.add_argument("--config_path", required=True, help="Path to expected scan config JSON")
    parser.add_argument("--log_out_dir", required=True, help="Path to save out csv log file")

    args = parser.parse_args()
    subject = f"sub-{args.subid}"
    input_dir = os.path.join(args.project_dir, "bids", subject)
    output_dir = os.path.join(args.log_out_dir, "qc-verify_nii_metadata")
    output_csv = os.path.join(output_dir, f"{subject}_qc_summary.csv")
    os.makedirs(output_dir, exist_ok=True)

    run_qc(input_dir=input_dir, config_path=args.config_path, output_csv=output_csv)