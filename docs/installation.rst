Installation
============

Prerequisites
-------------

Before using the SML fMRI Preprocessing Template, ensure you have:

- Access to a computing cluster with Slurm workload manager
- Singularity/Apptainer for container execution
- FreeSurfer license file
- Git for version control
- Python 3.6 or higher

Getting Started
---------------

1. **Create Repository from Template**

   Click the "Use this template" button on the `GitHub repository <https://github.com/shawntz/fmri>`_
   to create your own copy.

2. **Clone Your Repository**

   .. code-block:: bash

      git clone https://github.com/your-username/your-repo-name.git
      cd your-repo-name

3. **Configure Settings**

   Copy the settings template and customize for your study:

   .. code-block:: bash

      cp settings.template.sh settings.sh
      # Edit settings.sh with your study-specific parameters

4. **Set Up Subject List**

   Create your subject list file:

   .. code-block:: bash

      cp all-subjects.template.txt all-subjects.txt
      # Add your subject IDs (one per line, just the number without "sub-" prefix)

5. **Verify Paths**

   Ensure all paths in ``settings.sh`` are correct and accessible:

   - ``BASE_DIR`` - Your study's root directory
   - ``RAW_DIR`` - BIDS-formatted raw data location
   - ``TRIM_DIR`` - Destination for processed data
   - ``FREESURFER_LICENSE`` - Path to FreeSurfer license file

System Requirements
-------------------

**Minimum Requirements:**

- 8 CPU cores per subject
- 8GB RAM per subject
- 100GB storage per subject (for preprocessed outputs)

**Recommended:**

- 16 CPU cores per subject
- 32GB RAM per subject
- 200GB storage per subject

**Software Dependencies:**

- Slurm workload manager
- Singularity/Apptainer 3.0+
- FreeSurfer (via container)
- fMRIPrep (via container)
- dcm2niix (via container or installed locally)

Next Steps
----------

After installation, proceed to the :doc:`configuration` guide to set up
your preprocessing pipeline parameters.
