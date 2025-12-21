# Welcome to fMRIPrep Workbench Documentation

<!-- GitHub Pages badge will be active after deployment -->
<!-- [![Documentation](https://img.shields.io/badge/docs-github%20pages-blue)](https://shawntz.github.io/fmriprep-workbench/) -->

This documentation covers the fMRIPrep Workbench template, a generalizable
workflow for fMRI preprocessing that handles the full pipeline from scanner
acquisition downloads to fMRIPrep execution.

**Version:** 0.2.0

## Overview

The fMRIPrep Workbench transforms fMRI preprocessing scripts into a generalizable
workflow that handles:

- Automated transfer of scanner acquisitions from FlyWheel to server
- DICOM to NIfTI conversion with dcm2niix/heudiconv
- Dummy scan removal and fieldmap-based susceptibility distortion correction setup
- Quality control verification (metadata and volume counts)
- fMRIPrep anatomical-only workflows (for manual FreeSurfer editing)
- FreeSurfer manual editing utilities (download/upload with automatic backup)
- fMRIPrep full workflows (anatomical + functional)
- FSL FEAT statistical analysis (Level 1, 2, 3 GLM)
- Data management utilities (tarball/untar for inode optimization)
- Interactive TUI launcher for all pipeline steps

## Quick Start

### 1. Create Repository from Template

Click "Use this template" on the [GitHub repository](https://github.com/shawntz/fmriprep-workbench)
to create your own copy.

### 2. Clone Your Repository

```bash
git clone https://github.com/your-username/your-repo-name.git
cd your-repo-name
```

### 3. Configure Settings

Copy the configuration template and customize for your study:

```bash
cp config.template.yaml config.yaml
# Edit config.yaml with your study-specific parameters
```

### 4. Set Up Subject List

```bash
cp all-subjects.template.txt all-subjects.txt
# Add your subject IDs (one per line, just the number without "sub-" prefix)
```

### 5. Run the Pipeline

```bash
# Interactive mode (recommended)
./launch

# Or manual execution (14-step workflow)
./01-run.sbatch                      # Step 1: FlyWheel download
./02-run.sbatch                      # Step 2: DICOM conversion
./03-run.sbatch                      # Step 3: Prep for fMRIPrep
./04-run.sbatch                      # Step 4: QC metadata
./05-run.sbatch                      # Step 5: QC volumes
./06-run.sbatch                      # Step 6: fMRIPrep anat-only (optional)
./toolbox/download_freesurfer.sh     # Step 7: Download FreeSurfer (optional)
./toolbox/upload_freesurfer.sh       # Step 8: Upload FreeSurfer (optional)
./07-run.sbatch                      # Step 9: fMRIPrep full workflows
./08-fsl-glm/setup_glm.sh            # Step 10: FSL GLM setup
./08-run.sbatch <model-name>         # Step 11: FSL Level 1
./09-run.sbatch <model-name>         # Step 12: FSL Level 2
./10-run.sbatch <model-name>         # Step 13: FSL Level 3
./toolbox/tarball_sourcedata.sh      # Step 14: Tarball utility
```

## What's New in v0.2.0

**Breaking Changes:**

- Configuration migrated from `settings.sh` (Bash) to `config.yaml` (YAML)
- QC steps now dedicated pipeline steps (04-qc-metadata, 05-qc-volumes)
- SLURM job names changed to `fmriprep-workbench-{N}` pattern

**New Features:**

- YAML configuration for improved portability
- Automatic filtering of comments and blank lines in subject lists
- Dynamic configuration loading via `load_config.sh`

See [Changelog](changelog.md) for full details.

## Features

**Automated Transfer**
:   Transfer scanner acquisitions from FlyWheel to server

**DICOM Conversion**
:   Convert DICOM to NIfTI using heudiconv/dcm2niix

**Dummy Scan Removal**
:   Remove initial dummy scans based on configuration

**Distortion Correction**
:   Fieldmap-based susceptibility distortion correction setup

**Quality Control**
:   Built-in verification of metadata and volume counts

**fMRIPrep Integration**
:   Run anatomical-only or full workflows with FreeSurfer manual editing support

**FreeSurfer Editing**
:   Download/upload utilities with automatic backup for manual surface editing

**FSL FEAT Analysis**
:   Complete statistical analysis pipeline (Level 1, 2, 3 GLM)

**Data Management**
:   Tarball utility to optimize inode usage on shared filesystems

**Interactive TUI**
:   User-friendly launcher for all 14 pipeline steps

**YAML Configuration**
:   Portable, cross-platform configuration system

## Getting Help

- [GitHub Issues](https://github.com/shawntz/fmriprep-workbench/issues)
- [Contributing Guidelines](https://github.com/shawntz/fmriprep-workbench/blob/main/CONTRIBUTING.md)
