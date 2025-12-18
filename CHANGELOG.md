# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.8] - 2025-12-18


### 🚀 Features

### 🐛 Bug Fixes

### 📚 Documentation

### 🔧 Maintenance

### 💥 Breaking Changes
- No breaking changes

**Full Changelog**: https://github.com/shawntz/fmriprep-workbench/compare/v0.1.7...v0.1.8


## [0.1.7] - 2025-12-18


### 🚀 Features

### 🐛 Bug Fixes

### 📚 Documentation

### 🔧 Maintenance

### 💥 Breaking Changes
- No breaking changes

**Full Changelog**: https://github.com/shawntz/fmriprep-workbench/compare/v0.1.6...v0.1.7


## [0.1.6] - 2025-12-18


### 🚀 Features

### 🐛 Bug Fixes

### 📚 Documentation

### 🔧 Maintenance

### 💥 Breaking Changes
- No breaking changes

**Full Changelog**: https://github.com/shawntz/fmriprep-workbench/compare/v0.1.5...v0.1.6


## [0.1.5] - 2025-12-18


### 🚀 Features

### 🐛 Bug Fixes

### 📚 Documentation

### 🔧 Maintenance

### 💥 Breaking Changes
- No breaking changes

**Full Changelog**: https://github.com/shawntz/fmriprep-workbench/compare/v0.1.4...v0.1.5


## [0.1.4] - 2025-12-18


### 🚀 Features

### 🐛 Bug Fixes

### 📚 Documentation

### 🔧 Maintenance

### 💥 Breaking Changes
- No breaking changes

**Full Changelog**: https://github.com/shawntz/fmriprep-workbench/compare/v0.1.3...v0.1.4


## [0.1.3] - 2025-12-18


### 🚀 Features

### 🐛 Bug Fixes

### 📚 Documentation

### 🔧 Maintenance

### 💥 Breaking Changes
- No breaking changes

**Full Changelog**: https://github.com/shawntz/fmriprep-workbench/compare/v0.1.2...v0.1.3


## [0.1.2] - 2025-12-17


### 🚀 Features

### 🐛 Bug Fixes

### 📚 Documentation

### 🔧 Maintenance

### 💥 Breaking Changes
- No breaking changes

**Full Changelog**: https://github.com/shawntz/fmriprep-workbench/compare/v0.1.1...v0.1.2


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

**Full Changelog**: https://github.com/shawntz/fmriprep-workbench/compare/v0.0.0...v0.1.0


### Added
- Automated release workflow with version and changelog generation
- Conventional commits support for automatic versioning
- ReadTheDocs configuration for documentation hosting

## [1.0.0] - 2024-12-17

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

[Unreleased]: https://github.com/shawntz/fmri/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/shawntz/fmri/releases/tag/v1.0.0

[0.1.0]: https://github.com/shawntz/fmriprep-workbench/releases/tag/v0.1.0

[0.1.1]: https://github.com/shawntz/fmriprep-workbench/releases/tag/v0.1.1

[0.1.2]: https://github.com/shawntz/fmriprep-workbench/releases/tag/v0.1.2

[0.1.3]: https://github.com/shawntz/fmriprep-workbench/releases/tag/v0.1.3

[0.1.4]: https://github.com/shawntz/fmriprep-workbench/releases/tag/v0.1.4

[0.1.5]: https://github.com/shawntz/fmriprep-workbench/releases/tag/v0.1.5

[0.1.6]: https://github.com/shawntz/fmriprep-workbench/releases/tag/v0.1.6

[0.1.7]: https://github.com/shawntz/fmriprep-workbench/releases/tag/v0.1.7

[0.1.8]: https://github.com/shawntz/fmriprep-workbench/releases/tag/v0.1.8
