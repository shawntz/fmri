# dcm2niix Workflow

This directory contains scripts for converting DICOM files to NIfTI format using heudiconv.

## Files

- `dcm2niix.py`: Main Python script that handles DICOM extraction and conversion
- `dcm2niix.sh`: Shell wrapper script for submitting jobs
- `dcm_heuristic.py`: Heuristic file for heudiconv to organize BIDS structure

## Usage

### Standard Usage

```bash
./dcm2niix.sh 02-dcm2niix <fw_session_id> <subject_id>
```

### For Manually Merged Sessions

If you have manually merged scans from multiple acquisition sessions (which have different study identifiers), you may encounter an assertion error:

```
AssertionError: Conflicting study identifiers found [1.2.840.113619.6.475..., 1.2.840.113619.6.475...].
```

To bypass this check and process all DICOMs together regardless of study identifiers, use the `all` grouping strategy:

```bash
./dcm2niix.sh 02-dcm2niix <fw_session_id> <subject_id> all
```

### For Manually Configured DICOM Directories

If you have manually configured DICOM directories (not from a Flywheel tarball), use the `--skip-tar` flag to skip tar extraction and unzip steps:

```bash
./dcm2niix.sh 02-dcm2niix <fw_session_id> <subject_id> studyUID --skip-tar
```

When using this flag, ensure your DICOMs are already present in the expected directory structure: `/scratch/users/<user>/sub-<subid>/dcm2niix_work_dir/sub-<subid>/`

## Grouping Strategies

The `--grouping` flag controls how heudiconv groups DICOM files:

- **`studyUID`** (default): Groups DICOMs by StudyInstanceUID. This is the standard behavior and will fail if multiple study identifiers are found.
- **`all`**: Processes all DICOMs together regardless of study identifiers. Use this when you have manually merged scans from different sessions.

## Optional Flags

- **`--skip-tar`**: Skip tar extraction and unzip steps. Use this when working with manually configured DICOM directories that don't need extraction from Flywheel tarballs. When this flag is set, the script expects DICOMs to already be present in the target directory.

## Examples

```bash
# Standard processing
./dcm2niix.sh 02-dcm2niix 21940 001

# Processing merged sessions
./dcm2niix.sh 02-dcm2niix 21940 001 all

# Processing manually configured DICOM directories
./dcm2niix.sh 02-dcm2niix 21940 001 studyUID --skip-tar
```

## Direct Python Usage

You can also call the Python script directly:

```bash
python3 dcm2niix.py \
  --user your_sunet_id \
  --subid 001 \
  --exam_num 21940 \
  --project_dir /path/to/project \
  --fw_group_id group_id \
  --fw_project_id project_id \
  --task_id task_name \
  --sing_image_path /path/to/heudiconv.sif \
  --scripts_dir /path/to/scripts \
  --grouping all \
  --skip-tar  # Optional: skip tar extraction
```
