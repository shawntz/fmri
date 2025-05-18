#!/usr/bin/env python3
"""
Directory Checksum Comparison Script

This script compares two directories by calculating and comparing checksums
for all files. It automatically reports any differences, missing files, or extra files.

Usage:
    python dir_checksum_compare.py [dir1] [dir2] [--algorithm ALGORITHM]

Arguments:
    dir1            First directory for comparison
    dir2            Second directory for comparison
    --algorithm     Hash algorithm to use (default: sha256)
                    Options: md5, sha1, sha256, sha512
    --verbose, -v   Show additional details (matching files)

Example:
    python dir_checksum_compare.py /path/to/source /path/to/backup --algorithm md5
"""

import os
import sys
import hashlib
import argparse
from pathlib import Path
import time


def calculate_file_hash(file_path, algorithm='sha256', block_size=65536):
    """Calculate hash for a file using specified algorithm."""
    hash_funcs = {
        'md5': hashlib.md5,
        'sha1': hashlib.sha1,
        'sha256': hashlib.sha256,
        'sha512': hashlib.sha512
    }

    if algorithm not in hash_funcs:
        raise ValueError(f"Unsupported hash algorithm: {algorithm}")

    hash_obj = hash_funcs[algorithm]()

    try:
        with open(file_path, 'rb') as f:
            for block in iter(lambda: f.read(block_size), b''):
                hash_obj.update(block)
        return hash_obj.hexdigest()
    except IOError as e:
        return f"ERROR: {str(e)}"


def get_directory_checksums(dir_path, algorithm):
    """Recursively traverse directory and calculate checksums for all files."""
    checksums = {}
    dir_path = Path(dir_path).resolve()

    try:
        for root, _, files in os.walk(dir_path):
            for file in files:
                full_path = Path(root) / file
                rel_path = full_path.relative_to(dir_path)
                checksums[str(rel_path)] = calculate_file_hash(full_path, algorithm)
    except Exception as e:
        print(f"Error processing directory {dir_path}: {e}")
        sys.exit(1)

    return checksums


def compare_checksums(dir1_checksums, dir2_checksums):
    """Compare checksums between two directories and report differences."""
    all_files = sorted(set(dir1_checksums.keys()) | set(dir2_checksums.keys()))

    matching = 0
    different = 0
    only_in_first = 0
    only_in_second = 0

    results = {
        'matching': [],
        'different': [],
        'only_in_first': [],
        'only_in_second': []
    }

    for file in all_files:
        if file in dir1_checksums and file in dir2_checksums:
            if dir1_checksums[file] == dir2_checksums[file]:
                matching += 1
                results['matching'].append(file)
            else:
                different += 1
                results['different'].append(file)
        elif file in dir1_checksums:
            only_in_first += 1
            results['only_in_first'].append(file)
        else:
            only_in_second += 1
            results['only_in_second'].append(file)

    return {
        'stats': {
            'matching': matching,
            'different': different,
            'only_in_first': only_in_first,
            'only_in_second': only_in_second,
            'total_files': len(all_files)
        },
        'details': results
    }


def print_results(comparison_results, dir1_path, dir2_path, verbose=False):
    """Print comparison results in a readable format."""
    stats = comparison_results['stats']
    details = comparison_results['details']

    print("\n===== DIRECTORY CHECKSUM COMPARISON SUMMARY =====")
    print(f"Directory 1: {dir1_path}")
    print(f"Directory 2: {dir2_path}")
    print(f"Total files: {stats['total_files']}")
    print(f"Matching files: {stats['matching']}")
    print(f"Different files: {stats['different']}")
    print(f"Files only in first directory: {stats['only_in_first']}")
    print(f"Files only in second directory: {stats['only_in_second']}")

    # Always print changed files and files that exist only in one directory
    if stats['different'] > 0:
        print("\n----- FILES WITH DIFFERENT CHECKSUMS -----")
        for file in details['different']:
            print(f"  {file}")

    if stats['only_in_first'] > 0:
        print("\n----- FILES ONLY IN DIRECTORY 1 -----")
        for file in details['only_in_first']:
            print(f"  {file}")

    if stats['only_in_second'] > 0:
        print("\n----- FILES ONLY IN DIRECTORY 2 -----")
        for file in details['only_in_second']:
            print(f"  {file}")

    # Only print matching files if verbose flag is set
    if verbose and stats['matching'] > 0:
        print("\n----- MATCHING FILES -----")
        for file in details['matching']:
            print(f"  {file}")

    print("\n===== RESULT =====")
    if stats['different'] == 0 and stats['only_in_first'] == 0 and stats['only_in_second'] == 0:
        print("DIRECTORIES MATCH: All files are identical.")
    else:
        print("DIRECTORIES DIFFER: See details above.")


def main():
    parser = argparse.ArgumentParser(description='Compare two directories using file checksums')
    parser.add_argument('dir1', help='First directory for comparison')
    parser.add_argument('dir2', help='Second directory for comparison')
    parser.add_argument('--algorithm', default='sha256', choices=['md5', 'sha1', 'sha256', 'sha512'],
                        help='Hash algorithm to use (default: sha256)')
    parser.add_argument('--verbose', '-v', action='store_true',
                        help='Show additional details (matching files)')

    args = parser.parse_args()

    # Validate directories exist
    if not os.path.isdir(args.dir1):
        print(f"Error: Directory does not exist: {args.dir1}")
        sys.exit(1)

    if not os.path.isdir(args.dir2):
        print(f"Error: Directory does not exist: {args.dir2}")
        sys.exit(1)

    dir1_path = os.path.abspath(args.dir1)
    dir2_path = os.path.abspath(args.dir2)

    print(f"Comparing directories:")
    print(f"  Directory 1: {dir1_path}")
    print(f"  Directory 2: {dir2_path}")
    print(f"  Using algorithm: {args.algorithm}")

    # Calculate checksums
    start_time = time.time()
    print(f"\nCalculating checksums for directory 1...")
    dir1_checksums = get_directory_checksums(dir1_path, args.algorithm)
    print(f"Found {len(dir1_checksums)} files in directory 1")

    print(f"\nCalculating checksums for directory 2...")
    dir2_checksums = get_directory_checksums(dir2_path, args.algorithm)
    print(f"Found {len(dir2_checksums)} files in directory 2")

    # Compare and print results
    print("\nComparing checksums...")
    results = compare_checksums(dir1_checksums, dir2_checksums)
    print_results(results, dir1_path, dir2_path, args.verbose)

    elapsed_time = time.time() - start_time
    print(f"\nComparison completed in {elapsed_time:.2f} seconds.")


if __name__ == "__main__":
    main()

