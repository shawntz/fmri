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

### For Pre-Extracted Tar Files

If you have already extracted the Flywheel tar file manually, use the `--skip-tar` flag to skip tar extraction. The script will still unzip the `.dicom.zip` files found in the extracted directory:

```bash
./dcm2niix.sh 02-dcm2niix <fw_session_id> <subject_id> studyUID --skip-tar
```

When using this flag, ensure the tar contents are already extracted to: `/scratch/users/<user>/sub-<subid>/untar_<exam_num>/`

The script will then:
1. Skip extracting the `.tar` file (already done)
2. Find and unzip all `.dicom.zip` files in the extracted directory tree
3. Process the unzipped DICOM files as usual

## Grouping Strategies

The `--grouping` flag controls how heudiconv groups DICOM files:

- **`studyUID`** (default): Groups DICOMs by StudyInstanceUID. This is the standard behavior and will fail if multiple study identifiers are found.
- **`all`**: Processes all DICOMs together regardless of study identifiers. Use this when you have manually merged scans from different sessions.

## Optional Flags

- **`--skip-tar`**: Skip tar extraction step only. Use this when you've already extracted the Flywheel tar file manually. The script will still unzip the `.dicom.zip` files found in the extracted directory. When this flag is set, the script expects the tar contents to be at `/scratch/users/<user>/sub-<subid>/untar_<exam_num>/`.

## Examples

```bash
# Standard processing
./dcm2niix.sh 02-dcm2niix 21940 001

# Processing merged sessions
./dcm2niix.sh 02-dcm2niix 21940 001 all

# Processing with pre-extracted tar file
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
