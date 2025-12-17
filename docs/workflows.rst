Workflows
=========

This document provides detailed information about each preprocessing workflow
in the SML fMRI template.

Pipeline Overview
-----------------

The preprocessing pipeline is organized into sequential steps, each handling
a specific aspect of the fMRI preprocessing workflow:

.. code-block:: text

   FlyWheel → BIDS → dcm2niix → Prep → fMRIPrep Anat → fMRIPrep Full

Workflow Details
----------------

1. FlyWheel Transfer (01-fw2server)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Purpose:** Automated transfer of scanner acquisitions from FlyWheel to Server

**Inputs:**
   - FlyWheel project ID
   - Scanner acquisition metadata

**Outputs:**
   - Raw DICOM files on server storage

**Configuration:**
   - FlyWheel API credentials
   - Target directory structure

2. BIDS Conversion (02-bidsify)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Purpose:** Convert raw data to BIDS-compliant format

**Inputs:**
   - Raw DICOM files
   - Study metadata

**Outputs:**
   - BIDS-formatted dataset
   - Sidecar JSON files with metadata

**BIDS Structure:**

.. code-block:: text

   bids/
   ├── dataset_description.json
   ├── participants.tsv
   └── sub-<subject_id>/
       ├── anat/
       │   └── sub-<subject_id>_T1w.nii.gz
       ├── func/
       │   ├── sub-<subject_id>_task-<task>_run-01_bold.nii.gz
       │   └── sub-<subject_id>_task-<task>_run-01_bold.json
       └── fmap/
           └── sub-<subject_id>_dir-AP_epi.nii.gz

3. DICOM to NIfTI (03-dcm2niix)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Purpose:** Convert DICOM files to NIfTI format using dcm2niix

**Inputs:**
   - DICOM files

**Outputs:**
   - NIfTI files (.nii.gz)
   - JSON metadata files

**Features:**
   - Automatic metadata extraction
   - BIDS naming conventions
   - Compressed output (gzip)

4. Prep for fMRIPrep (04-prep-fmriprep)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Purpose:** Prepare data for fMRIPrep processing

**Key Operations:**

a. **Dummy Scan Removal**
   
   Remove initial dummy TRs (specified by ``n_dummy`` in settings):
   
   .. code-block:: bash
   
      # Configured in settings.sh
      n_dummy=5

b. **Fieldmap Setup**
   
   Configure fieldmap-based susceptibility distortion correction:
   
   - Map fieldmaps to BOLD runs
   - Update IntendedFor fields in JSON metadata
   - Validate fieldmap parameters

c. **Data Validation**
   
   - Check expected volume counts
   - Verify BIDS compliance
   - Validate JSON metadata

**Outputs:**
   - Trimmed BOLD files (without dummy scans)
   - Updated JSON metadata
   - Validated BIDS structure

5. fMRIPrep Anatomical (05-run-fmriprep)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Purpose:** Run fMRIPrep anatomical workflows only

**Use Case:** When manual FreeSurfer surface editing is needed

**Inputs:**
   - BIDS-formatted anatomical data
   - FreeSurfer license

**Outputs:**
   - FreeSurfer segmentation
   - Anatomical preprocessing outputs
   - Quality control reports

**Configuration:**

.. code-block:: bash

   # In settings.sh
   FMRIPREP_VERSION="24.0.1"
   FMRIPREP_OUTPUT_SPACES="MNI152NLin2009cAsym:res-2 anat fsnative fsaverage5"

**Execution:**

.. code-block:: bash

   ./05-run.sbatch --anat-only

6. fMRIPrep Complete (06-run-fmriprep)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Purpose:** Run complete fMRIPrep preprocessing (anatomical + functional)

**Inputs:**
   - BIDS-formatted data (anatomical and functional)
   - FreeSurfer outputs (if using edited surfaces)
   - Fieldmap data

**Outputs:**
   - Preprocessed BOLD data
   - Confound regressors
   - HTML quality reports
   - Anatomical-functional co-registration

**Processing Steps:**

1. Skull stripping
2. Brain tissue segmentation
3. Spatial normalization
4. Surface reconstruction (if not using existing)
5. BOLD preprocessing:
   
   - Slice timing correction
   - Motion correction
   - Susceptibility distortion correction (using fieldmaps)
   - Co-registration to anatomical
   - Normalization to template space
   - Resampling to target resolution

6. Confound estimation:
   
   - Motion parameters
   - CompCor components
   - Framewise displacement
   - DVARS

**Quality Metrics:**

.. code-block:: bash

   # Configured thresholds
   FMRIPREP_FD_SPIKE_THRESHOLD=0.9
   FMRIPREP_DVARS_SPIKE_THRESHOLD=3.0

Data Organization
-----------------

Output Structure
~~~~~~~~~~~~~~~~

.. code-block:: text

   derivatives/fmriprep-<version>/
   ├── dataset_description.json
   └── sub-<subject_id>/
       ├── sub-<subject_id>.html          # QC report
       ├── anat/
       │   ├── sub-<subject_id>_space-MNI152NLin2009cAsym_desc-preproc_T1w.nii.gz
       │   └── sub-<subject_id>_space-MNI152NLin2009cAsym_label-GM_probseg.nii.gz
       ├── func/
       │   ├── sub-<subject_id>_task-<task>_run-01_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz
       │   └── sub-<subject_id>_task-<task>_run-01_desc-confounds_timeseries.tsv
       └── figures/
           └── sub-<subject_id>_task-<task>_run-01_desc-carpetplot_bold.svg

Workflow Customization
----------------------

Per-Subject Control
~~~~~~~~~~~~~~~~~~~

Use subject ID modifiers for fine-grained control:

.. code-block:: text

   # Run only specific steps
   101:step4
   102:step4:step5

   # Force reprocessing
   103:force
   104:step5:force

   # Skip subjects
   105:skip

Resource Configuration
~~~~~~~~~~~~~~~~~~~~~~

Adjust resources per workflow:

.. code-block:: bash

   # General workflows
   export SLURM_CPUS="8"
   export SLURM_MEM="8G"
   export SLURM_TIME="2:00:00"

   # fMRIPrep workflows
   FMRIPREP_SLURM_CPUS_PER_TASK="16"
   FMRIPREP_SLURM_MEM_PER_CPU="4G"
   FMRIPREP_SLURM_TIME="12:00:00"

Advanced Topics
---------------

Parallel Processing
~~~~~~~~~~~~~~~~~~~

Control concurrent job execution:

.. code-block:: bash

   # Number of subjects to process simultaneously
   export SLURM_ARRAY_THROTTLE="10"

Output Spaces
~~~~~~~~~~~~~

Configure target output spaces:

.. code-block:: bash

   # Multiple output spaces
   FMRIPREP_OUTPUT_SPACES="MNI152NLin2009cAsym:res-2 anat fsnative fsaverage5"

Manual Interventions
~~~~~~~~~~~~~~~~~~~~

For subjects requiring manual editing:

1. Run anatomical workflow (step 5 with ``--anat-only``)
2. Download FreeSurfer outputs
3. Perform manual edits (e.g., skull strip correction)
4. Upload edited FreeSurfer directory
5. Run complete workflow (step 6) with edited surfaces

Best Practices
--------------

1. **Validate Each Step**
   
   Review outputs after each workflow before proceeding

2. **Monitor Resource Usage**
   
   Adjust Slurm parameters based on actual usage

3. **Document Deviations**
   
   Keep track of any manual interventions or parameter changes

4. **Regular Backups**
   
   Backup critical intermediate outputs (e.g., FreeSurfer directories)

5. **Version Control**
   
   Track fMRIPrep version and parameter changes for reproducibility

Next Steps
----------

- Return to :doc:`usage` for execution instructions
- See :doc:`configuration` for parameter details
- Review :doc:`changelog` for updates and improvements
