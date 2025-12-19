Welcome to SML fMRI Preprocessing Template Documentation
=========================================================

.. image:: https://readthedocs.org/projects/sml-fmri/badge/?version=latest
    :target: https://sml-fmri.readthedocs.io/en/latest/?badge=latest
    :alt: Documentation Status

This documentation covers the Stanford Memory Lab's fMRI preprocessing template,
a generalizable workflow for consistency within and across lab projects.

Overview
--------

The SML fMRI Preprocessing Template transforms internal fMRI preprocessing scripts
into a generalizable workflow that handles:

- Automated transfer of scanner acquisitions from FlyWheel to Server
- Raw to BIDS format conversion
- DICOM to NIfTI conversion with dcm2niix
- Dummy scan removal
- Fieldmap-based susceptibility distortion correction setup
- fMRIPrep anatomical and functional workflows
- Interactive TUI launcher for pipeline steps

Quick Start
-----------

1. Click "Use this template" to create your own repository
2. Clone your new repository
3. Copy ``settings.template.sh`` to ``settings.sh`` and customize
4. Follow the configuration guide below

.. toctree::
   :maxdepth: 2
   :caption: Contents:

   installation
   configuration
   usage
   workflows
   contributing
   changelog
   privacy

Features
--------

✅ Automated Transfer
   Transfer scanner acquisitions from FlyWheel to Server

✅ BIDS Conversion
   Convert raw data to BIDS format

✅ DICOM to NIfTI
   Use dcm2niix for conversion

✅ Dummy Scan Removal
   Remove initial dummy scans

✅ Distortion Correction
   Fieldmap-based susceptibility distortion correction

✅ fMRIPrep Integration
   Run anatomical and functional workflows

✅ Interactive TUI
   User-friendly launcher for pipeline steps

✅ Quality Control
   Built-in validation and QC utilities

Getting Help
------------

- `GitHub Issues <https://github.com/shawntz/fmri/issues>`_
- `Contributing Guidelines <https://github.com/shawntz/fmri/blob/main/CONTRIBUTING.md>`_
- `Stanford Memory Lab <https://memorylab.stanford.edu/>`_

Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
