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
    parser.add_argument("--grouping", action="store", default="all",
                        help="Heudiconv grouping strategy. Use 'all' to bypass the 'Conflicting study identifiers found' assertion when working with manually merged sessions. Default: 'all'")
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
    raw_dir = Path(f"{args.project_dir}")  # This receives DIRECTORIES_RAW_DIR from config (e.g., sourcedata/)
    bids_dir = raw_dir  # Output BIDS directly to raw_dir
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
    bids_dir.mkdir(parents=True, exist_ok=True)

    if args.skip_tar:
        print(f"[INFO] --skip-tar flag detected: Skipping tar extraction")
        print(f"[INFO] Tar file already extracted to: {untar_dir}")
        print(f"[INFO] Will search recursively for ALL .zip files (supports manually merged multi-session scans)")

        # For manual configurations where tar is already extracted
        # Find ALL zip files recursively (handles various manual merging strategies)
        flywheel_base_path = untar_dir / "scitran" / args.fw_group_id / args.fw_project_id

        if not flywheel_base_path.exists():
            raise FileNotFoundError(f"Flywheel base path not found: {flywheel_base_path}")

        # Recursively find all ZIP files
        all_zip_files = list(flywheel_base_path.glob("**/*.zip"))

        if not all_zip_files:
            raise FileNotFoundError(f"No .zip files found under {flywheel_base_path}")

        # Group by exam ID to show user what we found
        exam_ids = set()
        for zf in all_zip_files:
            # Extract exam ID from path (assumes format like .../exam_id/...)
            path_parts = zf.parts
            for part in path_parts:
                if part.isdigit() and len(part) >= 4:  # Exam IDs are typically 4+ digits
                    exam_ids.add(part)
                    break

        print(f"[INFO] Found {len(all_zip_files)} .zip file(s) across {len(exam_ids)} exam session(s):")
        for exam_id in sorted(exam_ids):
            exam_zip_count = sum(1 for zf in all_zip_files if exam_id in str(zf))
            print(f"  - Exam {exam_id}: {exam_zip_count} .zip files")

        # Unzip ALL found zip files
        print(f"[INFO] Unzipping all files to {dicom_extract_dir}")
        for zf in all_zip_files:
            subprocess.run(['unzip', '-qq', str(zf), '-d', str(dicom_extract_dir)], check=True)
    else:
        # Untar
        print(f"[INFO] Extracting {tar_input} -> {untar_dir}")
        shutil.move(str(tar_input), scratch_sub_dir / f"{args.exam_num}.tar")
        with tarfile.open(scratch_sub_dir / f"{args.exam_num}.tar") as tar:
            tar.extractall(path=untar_dir)

        # Unzip DICOMs from single exam session
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
    # When using --skip-tar, we need to handle potentially merged exam sessions
    # Process each exam session separately to avoid heudiconv's deduplication
    if args.skip_tar:
        # Find all exam directories
        exam_dirs = sorted([d for d in dicom_extract_dir.iterdir() if d.is_dir() and d.name.startswith(tuple('0123456789'))])
        exam_ids = sorted(set([d.name.split('_')[0] for d in exam_dirs]))

        if len(exam_ids) > 1:
            print(f"[INFO] Detected {len(exam_ids)} exam sessions: {', '.join(exam_ids)}")
            print(f"[INFO] Processing each exam as a separate session to avoid sequence deduplication")

            for session_num, exam_id in enumerate(exam_ids, start=1):
                session_id = f"ses-{session_num:02d}"
                print(f"\n[INFO] Processing exam {exam_id} as {session_id}")

                # Create session-specific work directory
                session_work_dir = scratch_work_dir / f"session_{exam_id}"
                session_work_dir.mkdir(parents=True, exist_ok=True)

                # Move only this exam's DICOMs to session work dir
                for dicom_dir in dicom_extract_dir.glob(f"{exam_id}_*"):
                    if dicom_dir.is_dir():
                        target = session_work_dir / dicom_dir.name
                        if not target.exists():
                            shutil.move(str(dicom_dir), str(session_work_dir))

                # Run heudiconv for this session
                # Use --dcmconfig to pass flags to dcm2niix: -ba n suppresses echo entity for single-echo sequences
                cmd = (
                    f"singularity run --cleanenv "
                    f"-B {session_work_dir}:/indir -B {bids_dir}:/outdir "
                    f"-e {args.sing_image_path} "
                    f"-d /indir/{{subject}}_*.dicom/*.dcm "
                    f"-o /outdir/ -f {heu_file} -s {args.subid} -ss {session_id} -c dcm2niix -b notop --overwrite "
                    f"--grouping {args.grouping} "
                    f"--dcmconfig \"-ba n\""
                )
                subprocess.run(cmd, shell=True, check=True)

                # Move DICOMs back for cleanup
                for dicom_dir in session_work_dir.glob(f"{exam_id}_*"):
                    if dicom_dir.is_dir():
                        shutil.move(str(dicom_dir), str(dicom_extract_dir))
        else:
            print(f"[INFO] Single exam session detected, processing normally")
            print(f"[INFO] Running heudiconv for sub-{args.subid}")
            print(f"[INFO] Using grouping strategy: {args.grouping}")
            cmd = (
                f"singularity run --cleanenv "
                f"-B {dicoms_dir}:/indir -B {bids_dir}:/outdir "
                f"-e {args.sing_image_path} "
                f"-d /indir/sub-{{subject}}/*.dicom/*.dcm "
                f"-o /outdir/ -f {heu_file} -s {args.subid} -c dcm2niix -b notop --overwrite "
                f"--grouping {args.grouping} "
                f"--dcmconfig \"-ba n\""
            )
            subprocess.run(cmd, shell=True, check=True)
    else:
        # Normal tar-based workflow
        print(f"[INFO] Running heudiconv for sub-{args.subid}")
        print(f"[INFO] Using grouping strategy: {args.grouping}")
        cmd = (
            f"singularity run --cleanenv "
            f"-B {dicoms_dir}:/indir -B {bids_dir}:/outdir "
            f"-e {args.sing_image_path} "
            f"-d /indir/sub-{{subject}}/*.dicom/*.dcm "
            f"-o /outdir/ -f {heu_file} -s {args.subid} -c dcm2niix -b notop --overwrite "
            f"--grouping {args.grouping} "
            f"--dcmconfig \"-ba n\""
        )
        subprocess.run(cmd, shell=True, check=True)

    print("[INFO] DICOM to BIDS conversion complete.")

if __name__ == "__main__":
    main()
