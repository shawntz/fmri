# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
