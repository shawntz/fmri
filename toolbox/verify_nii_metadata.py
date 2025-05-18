#!/usr/bin/env python3
import os
import json
import csv
import re
from glob import glob
import argparse

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

def collect_bids_files(subject_dir, task_name):
    files = []
    func_dir = os.path.join(subject_dir, "func")
    fmap_dir = os.path.join(subject_dir, "fmap")
    print(os.listdir(func_dir))

    func_pattern = re.compile(fr"sub-[^_]+_task-{task_name}_run-\d{{2}}_dir-PA_bold\\.nii\\.gz$")
    print(f"Regex: {func_pattern.pattern}")
    
    fmap_pattern = re.compile(r"sub-[^_]+_run-\d{2}_dir-AP_epi\\.nii\\.gz$")

    for f in glob(os.path.join(func_dir, "*.nii.gz")):
        if func_pattern.search(os.path.basename(f)):
            files.append(f)

    for f in glob(os.path.join(fmap_dir, "*.nii.gz")):
        if fmap_pattern.search(os.path.basename(f)):
            files.append(f)

    return files

def run_qc(subject_dir, task_name, config_path, output_csv):
    config = load_config(config_path)
    expected_by_series_number = get_expected_series_map(config)
    records = []

    bids_files = collect_bids_files(subject_dir, task_name)

    for nii_path in bids_files:
        base = os.path.basename(nii_path).replace(".nii.gz", "")
        json_path = os.path.join(os.path.dirname(nii_path), base + ".json")

        row = {
            "Filename": base,
            "SeriesNumber": None,
            "SeriesDescription": None,
            "MatchedSequence": "FAIL",
            "SequenceType": "",
            "ExpectedSeriesNumber": "",
            "ExpectedSeriesDescription": "",
            "Match": "FAIL",
            "RunFromDescription": "",
            "RunMatchToFilename": "N/A"
        }

        if not os.path.exists(json_path):
            row["SeriesDescription"] = "Missing JSON"
            records.append(row)
            continue

        with open(json_path, "r") as f:
            metadata = json.load(f)

        series_number = metadata.get("SeriesNumber")
        desc = metadata.get("SeriesDescription")

        row["SeriesNumber"] = series_number
        row["SeriesDescription"] = desc

        expected = expected_by_series_number.get(series_number)

        if expected:
            row["MatchedSequence"] = "PASS"
            row["SequenceType"] = expected["sequence_type"]
            row["ExpectedSeriesNumber"] = series_number
            row["ExpectedSeriesDescription"] = expected.get("series_description", "")

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
                        row["RunMatchToFilename"] = "PASS" if expected_fragment in base else "FAIL"
                        if row["RunMatchToFilename"] == "PASS":
                            row["Match"] = "PASS"
                    else:
                        row["Match"] = "PASS"
                else:
                    row["RunMatchToFilename"] = "FAIL"
                    row["Match"] = "FAIL"
            else:
                expected_desc = expected.get("series_description")
                if expected_desc:
                    row["Match"] = "PASS" if desc == expected_desc else "FAIL"
                else:
                    row["Match"] = "PASS"

        records.append(row)

    with open(output_csv, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=records[0].keys())
        writer.writeheader()
        writer.writerows(records)

    print(f"✅ QC summary written to: {output_csv}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run metadata QC for converted NIfTI files")
    parser.add_argument("--subid", required=True, help="Subject ID (e.g., 001)")
    parser.add_argument("--project_dir", required=True, help="Base project directory")
    parser.add_argument("--task_id", required=True, help="Original task name used at scanner")
    parser.add_argument("--config_path", required=True, help="Path to expected scan config JSON")
    parser.add_argument("--log_out_dir", required=True, help="Path to save out csv log file")

    args = parser.parse_args()
    subject = f"sub-{args.subid}"
    subject_dir = os.path.join(args.project_dir, "bids", subject)
    output_dir = os.path.join(args.log_out_dir, "qc-verify_nii_metadata")
    output_csv = os.path.join(output_dir, f"{subject}_qc_summary.csv")
    os.makedirs(output_dir, exist_ok=True)

    run_qc(subject_dir=subject_dir, task_name=args.task_id, config_path=args.config_path, output_csv=output_csv)