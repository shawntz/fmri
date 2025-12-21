# Freesurfer Manual Editing Workflow

This guide explains how to download Freesurfer anatomical outputs from your server, manually edit them to correct surface reconstruction errors, and upload them back for use in subsequent fMRIPrep runs.

## Overview

Freesurfer's automated surface reconstruction can sometimes produce errors in:
- Brain extraction (skull/dura included or brain excluded)
- White matter surface placement
- Pial surface placement
- Tissue segmentation

Manual editing allows you to correct these errors before running functional preprocessing.

## When to Edit Freesurfer Surfaces

You should consider manual editing if:
- Visual inspection reveals obvious skull stripping errors
- White matter or pial surfaces are incorrectly placed
- Tissue segmentation is clearly wrong
- You plan to use surface-based analysis (important for accurate registration)

**Important**: Only edit after running Step 6 (fMRIPrep anatomical only). Do NOT edit before fMRIPrep has completed anatomical processing.

## Workflow

### 1. Run fMRIPrep Anatomical Workflows (Step 6)

First, run fMRIPrep with the `--anat-only` flag to generate initial Freesurfer outputs:

```bash
./launch
# Select option 6: Run fMRIPrep anatomical workflows only

# Or run directly:
./06-run.sbatch
```

Wait for the job to complete. This will create Freesurfer directories in:
```
BASE_DIR/freesurfer/sub-<subject_id>/
```

### 2. Download Freesurfer Outputs

Download the Freesurfer outputs from the server to your local machine for editing:

#### Using the Interactive Launcher
```bash
./launch
# Select option 12: Download Freesurfer outputs for manual editing
```

#### Using the Script Directly
```bash
./toolbox/download_freesurfer.sh
```

You'll be prompted for:
- Remote server hostname (e.g., `login.sherlock.stanford.edu`)
- Your username (SUNet ID)
- Remote base directory (absolute path to your BASE_DIR)
- Which subjects to download

**Non-Interactive Mode:**
```bash
./toolbox/download_freesurfer.sh \
  --server login.sherlock.stanford.edu \
  --user mysunetid \
  --remote-dir /oak/stanford/groups/mylab/projects/mystudy \
  --local-dir ~/freesurfer_edits \
  --subjects sub-001,sub-002,sub-003

# Or download all subjects:
./toolbox/download_freesurfer.sh \
  --server login.sherlock.stanford.edu \
  --user mysunetid \
  --remote-dir /oak/stanford/groups/mylab/projects/mystudy \
  --all
```

Freesurfer outputs will be downloaded to `~/freesurfer_edits/` by default.

### 3. Edit Freesurfer Surfaces

Use Freeview (Freesurfer's visualization tool) or other editing tools to correct surfaces.

#### Launch Freeview

```bash
# Navigate to subject directory
cd ~/freesurfer_edits/sub-001

# Launch Freeview for brain mask editing
freeview -v mri/T1.mgz \
         -v mri/brainmask.mgz \
         -f surf/lh.white:edgecolor=blue \
         -f surf/lh.pial:edgecolor=red \
         -f surf/rh.white:edgecolor=blue \
         -f surf/rh.pial:edgecolor=red
```

#### Common Editing Tasks

**1. Brain Mask Editing**
Fix skull stripping errors:
```bash
freeview -v mri/T1.mgz -v mri/brainmask.mgz:colormap=heat:opacity=0.4
```
- Use the voxel edit tool to add/remove voxels from brainmask
- Save edited brainmask
- Rerun `recon-all -autorecon2-cp -autorecon3` after editing

**2. White Matter Edits**
Fix white matter intensity normalization:
```bash
freeview -v mri/T1.mgz -v mri/wm.mgz:colormap=heat
```
- Add control points to fix misclassified voxels
- Save as `tmp/control.dat`
- Rerun Freesurfer from control point step

**3. Surface Edits**
Manually adjust white/pial surfaces:
```bash
freeview -v mri/T1.mgz \
         -f surf/lh.white:edgecolor=blue \
         -f surf/lh.pial:edgecolor=red
```
- Use surface tools to push/pull vertices
- Most effective after fixing brainmask or WM issues

#### Rerunning Freesurfer After Edits

If you made edits that require reprocessing:

**After brainmask edits:**
```bash
cd ~/freesurfer_edits/sub-001
recon-all -autorecon2-cp -autorecon3 -s sub-001 -sd ~/freesurfer_edits
```

**After control point edits:**
```bash
cd ~/freesurfer_edits/sub-001
recon-all -autorecon2-cp -autorecon3 -s sub-001 -sd ~/freesurfer_edits
```

**After surface edits:**
- Surface edits are typically final and don't require reprocessing
- Verify edits look correct in Freeview

### 4. Upload Edited Freesurfer Outputs

Once you're satisfied with the edits, upload them back to the server:

#### Using the Interactive Launcher
```bash
./launch
# Select option 13: Upload edited Freesurfer outputs back to server
```

#### Using the Script Directly
```bash
./toolbox/upload_freesurfer.sh
```

You'll be prompted for:
- Remote server hostname
- Your username
- Remote base directory
- Which subjects to upload
- Confirmation (uploads are destructive!)

**Non-Interactive Mode:**
```bash
./toolbox/upload_freesurfer.sh \
  --server login.sherlock.stanford.edu \
  --user mysunetid \
  --remote-dir /oak/stanford/groups/mylab/projects/mystudy \
  --local-dir ~/freesurfer_edits \
  --subjects sub-001,sub-002,sub-003

# Upload all edited subjects:
./toolbox/upload_freesurfer.sh \
  --server login.sherlock.stanford.edu \
  --user mysunetid \
  --remote-dir /oak/stanford/groups/mylab/projects/mystudy \
  --all
```

**Important Safety Features:**
- **Automatic Backups**: Original Freesurfer outputs are backed up on the server as `{subject}.backup.{timestamp}`
- **Confirmation Prompts**: Multiple confirmations required before upload
- **No-Backup Flag**: Use `--no-backup` to skip backups (NOT recommended)

### 5. Run fMRIPrep Full Workflows (Step 7)

After uploading edited surfaces, run the full fMRIPrep workflows:

```bash
./launch
# Select option 7: Run remaining fMRIPrep steps

# Or run directly:
./07-run.sbatch
```

fMRIPrep will automatically detect and use your edited Freesurfer outputs instead of rerunning surface reconstruction.

## File Structure

### Downloaded Freesurfer Directory
```
~/freesurfer_edits/
└── sub-001/
    ├── mri/
    │   ├── T1.mgz                    # Original T1 image
    │   ├── brainmask.mgz             # Brain mask (editable)
    │   ├── wm.mgz                    # White matter mask (editable)
    │   ├── aseg.mgz                  # Segmentation
    │   └── norm.mgz                  # Intensity normalized
    ├── surf/
    │   ├── lh.white                  # Left hemisphere white surface
    │   ├── lh.pial                   # Left hemisphere pial surface
    │   ├── rh.white                  # Right hemisphere white surface
    │   ├── rh.pial                   # Right hemisphere pial surface
    │   ├── lh.inflated               # Inflated surface for viewing
    │   └── rh.inflated
    ├── label/
    │   └── ...                       # Cortical labels
    ├── stats/
    │   └── ...                       # Surface statistics
    └── tmp/
        └── control.dat               # Control points (if added)
```

### Server Backups
After upload, originals are backed up on the server:
```
BASE_DIR/freesurfer/
├── sub-001/                          # Edited version (active)
└── sub-001.backup.20251217_143022/   # Original (backup)
```

## Troubleshooting

### Download fails with "Permission denied"
- Verify you have SSH access to the server
- Check that your SSH keys are configured
- Ensure you have read permissions on the remote directory

### Upload fails or times out
- Check network connection
- Verify you have write permissions on the server
- Large Freesurfer directories may take time; use screen/tmux for long uploads

### Freeview won't launch
- Ensure Freesurfer is installed locally: `which freeview`
- Source Freesurfer setup: `source $FREESURFER_HOME/SetUpFreeSurfer.sh`
- Check X11 forwarding if on remote machine: `ssh -X ...`

### fMRIPrep still reruns Freesurfer
- Verify edited surfaces were uploaded to correct location
- Check that subject IDs match exactly (sub-001 vs sub-1)
- Ensure Freesurfer output has all required files

### Want to revert to original surfaces
Use the backup created during upload:
```bash
ssh user@server
cd /oak/stanford/groups/mylab/projects/mystudy/freesurfer
rm -rf sub-001
mv sub-001.backup.20251217_143022 sub-001
```

## Best Practices

1. **Always use Step 6 first**: Run anatomical-only workflows before editing
2. **Edit locally**: Never edit directly on the compute cluster
3. **Document changes**: Keep notes on what you edited and why
4. **Verify edits**: Always visually inspect before uploading
5. **Keep backups**: Use the automatic backup feature (don't use --no-backup)
6. **Test first**: Try the workflow on one subject before batch processing
7. **Use version control**: Consider keeping edited surfaces in a separate version-controlled directory

## Additional Resources

### Freesurfer Documentation
- [Freesurfer Manual Editing Guide](https://surfer.nmr.mgh.harvard.edu/fswiki/FsTutorial/TroubleshootingData)
- [Brainmask Editing](https://surfer.nmr.mgh.harvard.edu/fswiki/FsTutorial/ControlPoints)
- [Freeview Tutorial](https://surfer.nmr.mgh.harvard.edu/fswiki/FreeviewGuide)
- [Common Problems](https://surfer.nmr.mgh.harvard.edu/fswiki/FsTutorial/PialEdits)

### fMRIPrep Documentation
- [Using Existing Freesurfer](https://fmriprep.org/en/stable/usage.html#reusing-freesurfer-anatomical-segmentations)
- [Anatomical Processing](https://fmriprep.org/en/stable/workflows.html#anatomical-preprocessing)

### Tutorials
- [Freesurfer Editing Workflow Video](https://www.youtube.com/results?search_query=freesurfer+manual+editing)
- [Common Editing Scenarios](https://surfer.nmr.mgh.harvard.edu/fswiki/FsTutorial/TroubleshootingDataV6.0)

## Script Options Reference

### download_freesurfer.sh

```
Options:
  --server <hostname>        Remote server hostname
  --user <username>          Remote username
  --remote-dir <path>        Remote base directory (BASE_DIR)
  --local-dir <path>         Local download directory (default: ~/freesurfer_edits)
  --subjects <file|list>     Subject list file or comma-separated IDs
  --all                      Download all subjects
  -h, --help                 Show help message
```

### upload_freesurfer.sh

```
Options:
  --server <hostname>        Remote server hostname
  --user <username>          Remote username
  --remote-dir <path>        Remote base directory (BASE_DIR)
  --local-dir <path>         Local directory with edited outputs
  --subjects <file|list>     Subject list file or comma-separated IDs
  --all                      Upload all subjects in local directory
  --no-backup                Don't create backups (NOT recommended)
  -h, --help                 Show help message
```

## Example Complete Workflow

```bash
# 1. Run anatomical preprocessing
./06-run.sbatch

# Wait for job to complete, then:

# 2. Download Freesurfer outputs
./toolbox/download_freesurfer.sh \
  --server login.sherlock.stanford.edu \
  --user mysunetid \
  --remote-dir /oak/stanford/groups/mylab/projects/mystudy \
  --subjects all-subjects.txt

# 3. Edit surfaces locally
cd ~/freesurfer_edits/sub-001
freeview -v mri/T1.mgz -v mri/brainmask.mgz
# Make edits...

# 4. Rerun Freesurfer if needed
recon-all -autorecon2-cp -autorecon3 -s sub-001 -sd ~/freesurfer_edits

# 5. Upload edited surfaces
./toolbox/upload_freesurfer.sh \
  --server login.sherlock.stanford.edu \
  --user mysunetid \
  --remote-dir /oak/stanford/groups/mylab/projects/mystudy \
  --subjects sub-001

# 6. Run full fMRIPrep workflows
./07-run.sbatch
```

Your edited Freesurfer surfaces will now be used for functional preprocessing!
