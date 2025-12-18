#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Convert DICOM tarball to BIDS format using heudiconv.

@Author: Shawn Schwartz - Stanford Memory Lab
@Date: May 9, 2025
@Description: Extract metadata from scan dicom headers for heudiconv
@Dependencies: Python 3.9+
@Usage: Called by dcm2niix.sh as part of the preprocessing pipeline

Arguments:
    --subid: Subject ID without "sub-" prefix (e.g., '001')
    --bids-dir: Path to BIDS directory
    --task-id: Original task identifier
    --new-task-id: New task identifier (if renaming)
    --fmap-mapping: JSON string of fieldmap:BOLD run mapping
    --runs: Comma-separated list of run numbers
    --grouping: Heudiconv grouping strategy (default: 'studyUID', use 'all' for merged sessions)
"""

import argparse, os, shutil, tarfile, subprocess
from glob import glob
from pathlib import Path


def parse_args():
    parser = argparse.ArgumentParser(description='Convert DICOM tarball to BIDS.')
    parser.add_argument("--user", action="store", help="Your SUNet ID, e.g., janedoe")
    parser.add_argument("--subid", action="store", required=True, help="e.g. 001")
    parser.add_argument("--exam_num", action="store", required=True, help="e.g. 21940")
    parser.add_argument("--project_dir", action="store", required=True, help="Parent dir where project files live")
    parser.add_argument("--fw_group_id", action="store", required=True, help="Flywheel group ID (i.e., parent dir of all project IDs, fw://surname)")
    parser.add_argument("--fw_project_id", action="store", required=True, help="Flywheel Project ID (e.g., amass)")
    parser.add_argument("--task_id", action="store", required=True, help="Task name label that will appear in BIDS files")
    parser.add_argument("--sing_image_path", action="store", required=True, help="Path to the heudiconv singularity image, should be defined in settings.sh")
    parser.add_argument("--scripts_dir", action="store", required=True, help="Root path of scripts dir (i.e., the clone of this repo), should be defined in settings.sh")
    parser.add_argument("--grouping", action="store", default="studyUID",
                        help="Heudiconv grouping strategy. Use 'all' to bypass the 'Conflicting study identifiers found' assertion when working with manually merged sessions. Default: 'studyUID'")
    parser.add_argument("--skip-tar", action="store_true", default=False,
                        help="Skip tar extraction step. Use this flag when working with manually configured scan directories that don't need tar extraction.")
    return parser.parse_args()

def main():
    args = parse_args()

    if args.user is None:
        raise ValueError(
            "SUNet ID user argument not defined, please do so with the --user flag!"
        )

    scratch_base = Path(f"/scratch/users/{args.user}")
    scratch_sub_dir = scratch_base / f"sub-{args.subid}"
    untar_dir = scratch_sub_dir / f"untar_{args.exam_num}"
    oak_base = Path(f"{args.project_dir}")
    bids_dir = oak_base / "bids"
    scratch_work_dir = scratch_sub_dir / f"dcm2niix_work_dir"
    dicoms_dir = scratch_work_dir
    code_dir = Path(f"{args.scripts_dir}")
    heu_file = code_dir / "dcm_heuristic.py"

    # Source and target DICOM tar
    tar_input = scratch_base / f"fw_{args.exam_num}" / "dicoms" / f"{args.exam_num}.tar"
    tar_target = scratch_work_dir / f"sub-{args.subid}.tar"

    # Make needed dirs
    dicom_extract_dir = scratch_work_dir / f"sub-{args.subid}"
    dicom_extract_dir.mkdir(parents=True, exist_ok=True)
    untar_dir.mkdir(parents=True, exist_ok=True)

    if args.skip_tar:
        print(f"[INFO] --skip-tar flag detected: Skipping tar extraction")
        print(f"[INFO] Using manually configured scan directory: {dicom_extract_dir}")
        print(f"[INFO] Ensure DICOMs are already present in this directory")

        # For manual configurations, expect DICOMs to already be in the extract directory
        # Skip tar extraction and unzip steps entirely
    else:
        # Untar
        print(f"[INFO] Extracting {tar_input} -> {untar_dir}")
        shutil.move(str(tar_input), scratch_sub_dir / f"{args.exam_num}.tar")
        with tarfile.open(scratch_sub_dir / f"{args.exam_num}.tar") as tar:
            tar.extractall(path=untar_dir)

        # Unzip DICOMs
        flywheel_base_path = untar_dir / "scitran" / args.fw_group_id / args.fw_project_id
        subject_dirs = glob(f"{flywheel_base_path}/*/{args.exam_num}")
        if not subject_dirs:
            raise FileNotFoundError(f"No matching subject folder found under {flywheel_base_path}/*/{args.exam_num}")
        subject_dir = Path(subject_dirs[0])

        print(f"[INFO] Unzipping all zip files from {subject_dir}")
        for zf in subject_dir.glob("**/*.zip"):
            subprocess.run(['unzip', '-qq', str(zf), '-d', str(dicom_extract_dir)], check=True)

    # Delete screenshots
    for pattern in ["*2000*.dicom", "*4000*.dicom", "*_200*.dicom"]:
        for f in dicom_extract_dir.glob(pattern):
            print(f"[INFO] Removing {f}")
            if f.is_file():
                f.unlink()
            elif f.is_dir():
                shutil.rmtree(f)

    print(f"[INFO] Screenshot DICOMs deleted from {dicom_extract_dir}")

    # Validate DICOM files exist before running heudiconv
    # Check for DICOM files with various extensions (case-insensitive)
    # Note: Using multiple patterns for Python 3.9+ compatibility
    # (glob's case_sensitive parameter was added in Python 3.12)
    dicom_patterns = ["**/*.dcm", "**/*.DCM", "**/*.dicom", "**/*.DICOM"]
    dicom_files = []
    for pattern in dicom_patterns:
        dicom_files.extend(dicom_extract_dir.glob(pattern))
    
    if not dicom_files:
        raise FileNotFoundError(
            f"No DICOM files found in {dicom_extract_dir}. "
            f"Please verify the ZIP files were extracted correctly. "
            f"Searched for patterns: {', '.join(dicom_patterns)}"
        )
    
    print(f"[INFO] Found {len(dicom_files)} DICOM files in {dicom_extract_dir}")
    
    # Log directory structure for debugging
    # Build a directory-to-file-count mapping in a single pass
    dir_file_counts = {}
    for f in dicom_files:
        parent_dir = f.parent
        dir_file_counts[parent_dir] = dir_file_counts.get(parent_dir, 0) + 1

    dicom_dirs = list(dir_file_counts.keys())
    print(f"[INFO] DICOM files are organized in {len(dicom_dirs)} directories:")
    for d in sorted(dicom_dirs)[:5]:  # Show first 5 directories
        file_count = dir_file_counts[d]
        print(f"  - {d.name}: {file_count} files")
    if len(dicom_dirs) > 5:
        print(f"  ... and {len(dicom_dirs) - 5} more directories")

    # Clear heudiconv cache to avoid using stale file paths
    # This is especially important when manually curating directories
    heudiconv_cache = bids_dir / ".heudiconv" / args.subid
    if heudiconv_cache.exists():
        print(f"[INFO] Removing stale heudiconv cache: {heudiconv_cache}")
        shutil.rmtree(heudiconv_cache)

    # Cleanup
    # shutil.rmtree(scratch_sub_dir)
    # print(f"[INFO] Cleaned up temporary dir {scratch_sub_dir}")

    # Run heudiconv
    print(f"[INFO] Running heudiconv for sub-{args.subid}")
    print(f"[INFO] Using grouping strategy: {args.grouping}")
    cmd = (
        f"singularity run --cleanenv "
        f"-B {dicoms_dir}:/indir -B {bids_dir}:/outdir "
        f"-e {args.sing_image_path} "
        f"-d /indir/sub-{{subject}}/*.dicom/*.dcm "
        f"-o /outdir/ -f {heu_file} -s {args.subid} -c dcm2niix -b notop --overwrite "
        f"--grouping {args.grouping}"
    )
    subprocess.run(cmd, shell=True, check=True)

    print("[INFO] DICOM to BIDS conversion complete.")

if __name__ == "__main__":
    main()
