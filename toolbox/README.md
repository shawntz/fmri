# FMRI Preprocessing Toolbox

This directory contains utility scripts for quality control, diagnostics, and data validation in the fMRI preprocessing pipeline.

## Available Tools

### 1. Diagnostic Scan Volume Checker

**Script**: `summarize_bold_scan_volume_counts.sh`

This diagnostic tool compares actual vs expected volumes in scan files to identify potential data quality issues.

#### Features:
- Checks BOLD and fieldmap scan volumes against expected values
- Validates both pre-trimmed (raw) and post-trimmed data
- **Timestamped outputs** - Each run creates a new timestamped directory to preserve diagnostic history
- **Automatic summary generation** - Creates a detailed report highlighting problematic subjects

#### Usage:
```bash
# From the root of your scripts directory
cd /path/to/your/scripts
./toolbox/summarize_bold_scan_volume_counts.sh
```

#### Output:
The script creates a timestamped directory under `logs/diagnostics/YYYYMMDD_HHMMSS/` containing:

1. **CSV file** (`scan_volumes_summary.csv`):
   - Detailed results for every subject and scan
   - Columns: subject_id, scan_type, run_number, file_path, expected_volumes, actual_volumes, status

2. **Summary report** (`diagnostic_summary.txt`):
   - Overall statistics (success rate, total errors, etc.)
   - Issue breakdown by scan type
   - **Problematic subjects list** - Quick identification of subjects needing review
   - Detailed error information for each problematic subject
   - List of subjects with no errors

#### Example Output Structure:
```
logs/
└── diagnostics/
    ├── 20251217_143022/
    │   ├── scan_volumes_summary.csv
    │   └── diagnostic_summary.txt
    └── 20251217_150145/
        ├── scan_volumes_summary.csv
        └── diagnostic_summary.txt
```

#### Configuration:
The tool uses settings from your `config.yaml` file (loaded via `load_config.sh`):
- `EXPECTED_BOLD_VOLS` - Expected number of volumes in BOLD scans
- `EXPECTED_BOLD_VOLS_AFTER_TRIMMING` - Expected volumes after trimming
- `EXPECTED_FMAP_VOLS` - Expected number of volumes in fieldmap scans
- `run_numbers` - Array of run numbers to check
- `fmap_mapping` - Mapping of fieldmap runs to BOLD runs

### 2. NIfTI Metadata Verifier

**Script**: `verify_nii_metadata.py`

Validates BIDS metadata in NIfTI JSON sidecar files.

#### Usage:
```bash
python3 toolbox/verify_nii_metadata.py \
  --subid 001 \
  --project_dir /path/to/project \
  --task_id originalTask \
  --new_task_id renamedTask \
  --config_path scan-config.json \
  --log_out_dir /path/to/logs
```

### 3. Summary Diagnostics Generator

**Script**: `summarize_diagnostics.py`

Generates summary reports from diagnostic CSV files. This is automatically called by `summarize_bold_scan_volume_counts.sh`, but can also be run independently.

#### Usage:
```bash
python3 toolbox/summarize_diagnostics.py \
  --csv /path/to/scan_volumes_summary.csv \
  --output-dir /path/to/output
```

## Requirements

- Python 3.9+
- FSL (for `fslnvols` command)
- Bash shell
- Access to your BIDS-formatted data directories

## Tips

- Run diagnostics regularly during preprocessing to catch issues early
- Review the summary report to quickly identify which subjects need attention
- Compare timestamped diagnostic runs to track improvements over time
- The CSV output can be imported into spreadsheet software for additional analysis

## Troubleshooting

**Issue**: "File not found" errors
- **Solution**: Verify that `directories.raw_dir` and `directories.trim_dir` in `config.yaml` are correctly set and accessible

**Issue**: Module load errors
- **Solution**: Ensure FSL and Python modules are available on your system

**Issue**: Permission denied
- **Solution**: Make sure scripts are executable: `chmod +x toolbox/*.sh`

## Contributing

Have suggestions for improving these tools? Please see the main [Contributing Guidelines](../CONTRIBUTING.md).
