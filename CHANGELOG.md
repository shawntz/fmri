# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2025-12-21

### 🚀 Features

- **Docker Containerization**: Complete Docker support with multi-platform images (linux/amd64, linux/arm64)
  - Dockerfile with Ubuntu 22.04, FSL, Python 3.11, and all dependencies
  - Docker wrapper script (`fmriprep-workbench`) with commands: start, stop, launch, shell, logs, status, exec, pull, build, remove
  - Docker Compose configuration for easy deployment
  - Singularity/Apptainer support for HPC clusters
  - Automated CI/CD pipeline to Docker Hub on release tags
- **FSL FEAT Statistical Analysis Pipeline** (Steps 10-13):
  - Complete GLM analysis workflow (Level 1, 2, 3)
  - Interactive setup utility with model configuration
  - Support for condition keys, contrasts, and confound regressors
  - SLURM array job integration for parallel processing
  - Comprehensive documentation in `10-fsl-glm/README.md`
- **FreeSurfer Manual Editing Workflow** (Steps 7-8):
  - Download/upload utilities for manual surface editing
  - Automatic timestamped backups before upload
  - Support for batch operations on multiple subjects
  - Interactive and non-interactive modes
  - Complete workflow documentation in `toolbox/FREESURFER_EDITING.md`
- **14-Step Pipeline Architecture**:
  - Expanded from 7 to 14 steps for complete end-to-end workflow
  - Steps 1-6: Download, conversion, prep, QC
  - Steps 7-8: FreeSurfer editing workflow
  - Step 9: Full fMRIPrep execution
  - Steps 10-13: FSL FEAT GLM analysis
  - Step 14: Data management utilities
- **Documentation System Migration**:
  - Migrated from Sphinx (RST) to MkDocs (Markdown)
  - Material theme with dark mode support
  - PDF export capability
  - Git revision dates
  - Improved navigation and search
  - Privacy-focused analytics with Seline

### 🐛 Bug Fixes

- **Subject List Processing**: Filter comments and empty lines in subject list files
- **DICOM Conversion**:
  - Fix multi-session handling with `--skip-tar` flag
  - Remove unnecessary `--dcmconfig` flag
  - Handle single-echo sequences correctly (no `_echo-1` suffix)
  - Fix positional argument issues with heudiconv grouping strategy
- **QC Scripts**: Write `processed_subjects.txt` to `SLURM_LOG_DIR` instead of repo root
- **Launch Script**: Fix menu item mapping to align with correct sbatch scripts
- **Directory Structure**: Rename directories to match 14-step workflow:
  - `07-run-fmriprep` → `09-run-fmriprep`
  - `08-fsl-glm` → `10-fsl-glm`
- **File Handle Leaks**: Use context managers for all file operations in FSL GLM scripts
- **Import Statements**: Replace wildcard imports with explicit imports
- **Container Management**: Replace fixed sleep delays with container readiness polling

### 📚 Documentation

- **Docker Documentation**:
  - Complete installation guide for Docker and Singularity
  - Docker usage guide with container management
  - GitHub Secrets setup guide for CI/CD
  - HPC cluster integration examples
  - Troubleshooting section
- **Pipeline Documentation**:
  - Updated all docs to reflect 14-step workflow
  - FSL GLM pipeline comprehensive guide
  - FreeSurfer editing workflow guide
  - Updated configuration guide with all new parameters
  - Usage examples for all pipeline steps
- **Version Placeholders**: Replace hardcoded version numbers with `vX.Y.Z` placeholders
- **Fix Documentation Parsing**: Correct include-markdown paths for CONTRIBUTING.md and CHANGELOG.md

### 🔧 Maintenance

- **Code Quality Improvements**:
  - Remove unused variables and fix indentation
  - Use context managers for all file operations
  - Fix pre-existing bugs in FSL GLM scripts
  - Remove orphaned code referencing undefined modules
  - Improve error handling and logging
- **Security Enhancements**:
  - Use official neuro.debian.net domain instead of mirrors
  - Eliminate insecure HTTP downloads
  - Remove HKP keyserver fallback
- **Release Automation**:
  - Automated changelog generation
  - AI-powered release process documentation
  - GitHub Actions workflows for Docker publishing and docs deployment
- **Configuration Management**:
  - Move FreeSurfer script defaults to `config.yaml`
  - Fix boolean handling in configuration
  - Support for project config YAML in directory paths

### 💥 Breaking Changes

- **Directory Renaming**:
  - Step 7 (fMRIPrep full) → Step 9 (directory: `09-run-fmriprep/`)
  - Step 8 (FSL GLM) → Steps 10-13 (directory: `10-fsl-glm/`)
  - **Migration**: Update any custom scripts referencing old directory names
- **Pipeline Structure**: 14-step workflow replaces previous 7-step structure
  - **Migration**: Review the updated pipeline documentation and adjust workflows accordingly
- **Documentation Format**: Migration from Sphinx to MkDocs
  - **Migration**: Documentation now built with `mkdocs build` instead of `sphinx-build`

**Full Changelog**: https://github.com/shawntz/fmriprep-workbench/compare/v0.1.8...v0.3.0

## [0.2.0] - 2025-12-18

### 🚀 Features
- **YAML Configuration System**: Replaced `settings.sh` with `config.yaml` for improved portability and cross-platform compatibility
- **Pipeline Restructuring**: Reorganized QC steps 4 and 5 into dedicated pipeline directories (`04-qc-metadata`, `05-qc-volumes`)
- **Unified Job Naming**: All SLURM jobs now use consistent `fmriprep-workbench-{N}` naming pattern
- **Dynamic Configuration Loading**: New `load_config.sh` script parses YAML configuration and exports environment variables
- **Enhanced Subject File Handling**: Automatic filtering of comment lines and blank lines in subject list files

### 🐛 Bug Fixes
- **Subject Counting**: Fixed subject count calculation to properly skip comment lines (starting with `#`) and blank lines
- **SLURM Array Indexing**: Fixed off-by-one errors in SLURM array task ID to subject list line mapping
- **Subject File Selection**: Fixed scripts to use `SELECTED_SUBJECTS_FILE` instead of hardcoded step-specific files
- **Interactive Prompts**: Fixed unwanted subject file selection prompts in steps 1 and 2 by adding `SKIP_SUBJECTS_PROMPT` flag
- **Configuration Variable Names**: Fixed variable name mismatches between YAML flattening and shell aliases
- **Directory Structure**: Separated `STEP_NAME` (for directories) from `JOB_NAME` (for SLURM display) to maintain log organization

### 📚 Documentation
- **Configuration Guide**: Updated docs to reflect YAML-based configuration system
- **Workflow Documentation**: Updated pipeline steps to include steps 4 and 5 as first-class workflow components
- **Version Sync**: Updated documentation version to 0.2.0 to match package version
- **CLAUDE.md**: Comprehensive updates reflecting new architecture and configuration system

### 🔧 Maintenance
- **Template Consistency**: Aligned `config.template.yaml` with actual configuration structure
- **Code Organization**: Improved separation of concerns between configuration loading and script execution
- **Log Directory Management**: Standardized log directory paths across all pipeline steps

### 💥 Breaking Changes
- **Configuration Format**: Migration from `settings.sh` (Bash) to `config.yaml` (YAML) - requires configuration file update
  - **Migration Path**: Copy `config.template.yaml` to `config.yaml` and configure for your study
  - Old `settings.sh` files are no longer used
- **QC Steps Renaming**: Toolbox-based QC steps now use dedicated directories:
  - `toolbox/verify_nii_metadata.sh` → `04-run.sbatch` (calls `04-qc-metadata/verify_metadata.sh`)
  - `toolbox/summarize_bold_scan_volume_counts.sh` → `05-run.sbatch` (calls `05-qc-volumes/check_volumes.sh`)
- **SLURM Job Names**: Job names changed from step-based (e.g., `03-prep-fmriprep`) to numbered (e.g., `fmriprep-workbench-3`)

**Full Changelog**: https://github.com/shawntz/fmriprep-workbench/compare/v0.1.1...v0.2.0


## [0.1.1] - 2025-12-17


### 🚀 Features

### 🐛 Bug Fixes
Fix: Add parameter configs for diagnostic toolbox options 9 and 10

### 📚 Documentation

### 🔧 Maintenance

### 💥 Breaking Changes
- No breaking changes

**Full Changelog**: https://github.com/shawntz/fmriprep-workbench/compare/v0.1.0...v0.1.1


## [0.1.0] - 2025-12-17


### 🚀 Features
- feat(01-prepare): add core `prepare_fmri.sh` script
- feat(01-prepare): add core `update_fmap_metadata.py` script
- feat(01-prepare): add core `submit_job.sbatch` executable
- feat(fmriprep): test scripts
- feat: gracefully skip missing bold runs instead of quitting
- feat: add dynamic subject txt files to pipeline steps
- feat: add new `pull_fmriprep_reports` utility script in the new `tools/` directory
- feat(TUI): add interactive launcher component
- feat: frontend work on flywheel downloader utility script
- feat: add changelog, release workflow automation, and ReadTheDocs integration

### 🐛 Bug Fixes

### 📚 Documentation
- docs: add README for documentation directory

### 🔧 Maintenance
- chore: update gitignore
- chore: update LICENSE
- chore: add contributing guidelines
- chore(readme): add first complete draft with info and instructions
- chore(README): fix markdown table formatting issues
- chore: relocate job submitter script
- chore: update settings template
- chore: clean up slurm args in `submit_01.sbatch`
- chore: rename sbatch run file
- chore: clean up INFO logs in `01-run.sbatch`
- chore: clean up log messages in `prepare_fmri.sh`
- chore: make `update_fmap_metadata.py` executable
- chore: update logging methods
- chore: restructure subjects.txt files
- chore: update values in `settings.template.sh`
- chore: restructure subjects template file
- chore: update subjects txt file approach
- chore: add new log statements
- chore: update readme
- chore: update `01-run.sbatch`
- chore: update `02-run.sbatch`
- chore: update README.md
- chore: lint `prepare_fmri.sh`
- chore: fix #5
- chore: lint `fmriprep.sh`
- refactor: migrate `fw-downloader` to independent step
- refactor(sbatch): run scripts
- refactor(launch): window with new options

### 💥 Breaking Changes
- No breaking changes

**Full Changelog**: https://github.com/shawntz/fmriprep-workbench/compare/v0.0.1...v0.1.0


### Added
- Automated release workflow with version and changelog generation
- Conventional commits support for automatic versioning
- ReadTheDocs configuration for documentation hosting

## [0.0.1] - 2025-12-17

### Added
- Initial release of SML fMRI preprocessing template
- Automated transfer of scanner acquisitions from FlyWheel to Server
- Raw to BIDS format conversion support
- dcm2niix DICOM to NIfTI converter integration
- Dummy scan removal functionality
- Fieldmap-based susceptibility distortion correction setup for fMRIPrep
- fMRIPrep anatomical workflow support
- Interactive TUI launcher for pipeline steps
- Configuration templates and examples
- Quality control utilities
- BIDS metadata management tools
- Subject ID suffix modifiers for granular per-subject control
- Comprehensive documentation and usage guides

### Features
- Fieldmap-based distortion correction
- Dummy scan removal
- BIDS-compliance validation
- JSON metadata management
- Quality control checks
- Slurm workload manager integration
- Configurable preprocessing pipelines

[Unreleased]: https://github.com/shawntz/fmriprep-workbench/compare/v0.3.0...HEAD

[0.0.1]: https://github.com/shawntz/fmriprep-workbench/releases/tag/v0.0.1

[0.1.0]: https://github.com/shawntz/fmriprep-workbench/releases/tag/v0.1.0

[0.1.1]: https://github.com/shawntz/fmriprep-workbench/releases/tag/v0.1.1

[0.2.0]: https://github.com/shawntz/fmriprep-workbench/releases/tag/v0.2.0

[0.3.0]: https://github.com/shawntz/fmriprep-workbench/releases/tag/v0.3.0
