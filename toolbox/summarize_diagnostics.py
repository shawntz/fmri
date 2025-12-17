#!/usr/bin/env python3
"""
Summarize diagnostic results from scan volume checks.
Generates a pivot table and identifies problematic subjects requiring review.

@Author: Shawn Schwartz - Stanford Memory Lab
@Date: December 17, 2025
"""

import sys
import csv
import argparse
from collections import defaultdict
from pathlib import Path


def load_csv(csv_path):
    """Load CSV file and return data as list of dictionaries."""
    if not Path(csv_path).exists():
        print(f"[ERROR] CSV file not found: {csv_path}")
        sys.exit(1)
    
    with open(csv_path, 'r') as f:
        reader = csv.DictReader(f)
        return list(reader)


def generate_summary(csv_path, output_dir):
    """
    Generate summary report from diagnostic CSV.
    
    Args:
        csv_path: Path to the diagnostic CSV file
        output_dir: Directory to save summary report
    """
    data = load_csv(csv_path)
    
    if not data:
        print("[WARNING] No data found in CSV file")
        return
    
    # Track statistics by subject
    subject_stats = defaultdict(lambda: {
        'total_checks': 0,
        'errors': 0,
        'ok': 0,
        'issues': []
    })
    
    # Track issues by type
    issue_types = defaultdict(int)
    
    # Process each row
    for row in data:
        subject_id = row.get('subject_id', 'UNKNOWN')
        status = row.get('status', 'UNKNOWN')
        scan_type = row.get('scan_type', 'UNKNOWN')
        run_number = row.get('run_number', 'UNKNOWN')
        expected_volumes = row.get('expected_volumes', 'UNKNOWN')
        actual_volumes = row.get('actual_volumes', 'UNKNOWN')
        
        subject_stats[subject_id]['total_checks'] += 1
        
        if status == 'ERROR':
            subject_stats[subject_id]['errors'] += 1
            issue_detail = f"{scan_type} run-{run_number}: expected {expected_volumes}, got {actual_volumes}"
            subject_stats[subject_id]['issues'].append(issue_detail)
            issue_types[scan_type] += 1
        elif status == 'OK':
            subject_stats[subject_id]['ok'] += 1
    
    # Generate summary report
    output_path = Path(output_dir) / 'diagnostic_summary.txt'
    
    with open(output_path, 'w') as f:
        f.write("=" * 80 + "\n")
        f.write("FMRI DIAGNOSTIC SCAN VOLUME CHECK - SUMMARY REPORT\n")
        f.write("=" * 80 + "\n\n")
        
        # Overall statistics
        total_subjects = len(subject_stats)
        total_checks = sum(s['total_checks'] for s in subject_stats.values())
        total_errors = sum(s['errors'] for s in subject_stats.values())
        total_ok = sum(s['ok'] for s in subject_stats.values())
        
        f.write("OVERALL STATISTICS\n")
        f.write("-" * 80 + "\n")
        f.write(f"Total Subjects Checked: {total_subjects}\n")
        f.write(f"Total Checks Performed: {total_checks}\n")
        f.write(f"Checks Passed (OK):     {total_ok}\n")
        f.write(f"Checks Failed (ERROR):  {total_errors}\n")
        f.write(f"Success Rate:           {(total_ok / total_checks * 100):.1f}%\n\n")
        
        # Issue breakdown by scan type
        if issue_types:
            f.write("ISSUE BREAKDOWN BY SCAN TYPE\n")
            f.write("-" * 80 + "\n")
            for scan_type, count in sorted(issue_types.items()):
                f.write(f"{scan_type:20s}: {count} errors\n")
            f.write("\n")
        
        # Problematic subjects
        problematic_subjects = {
            sid: stats for sid, stats in subject_stats.items() 
            if stats['errors'] > 0
        }
        
        if problematic_subjects:
            f.write("PROBLEMATIC SUBJECTS REQUIRING REVIEW\n")
            f.write("=" * 80 + "\n\n")
            
            for subject_id in sorted(problematic_subjects.keys()):
                stats = problematic_subjects[subject_id]
                f.write(f"Subject: {subject_id}\n")
                f.write(f"  Total Checks: {stats['total_checks']}\n")
                f.write(f"  Passed:       {stats['ok']}\n")
                f.write(f"  Failed:       {stats['errors']}\n")
                f.write(f"  Issues:\n")
                for issue in stats['issues']:
                    f.write(f"    - {issue}\n")
                f.write("\n")
        else:
            f.write("EXCELLENT! All subjects passed all checks.\n\n")
        
        # Subjects with no errors
        clean_subjects = [
            sid for sid, stats in subject_stats.items() 
            if stats['errors'] == 0
        ]
        
        if clean_subjects:
            f.write("SUBJECTS WITH NO ERRORS\n")
            f.write("-" * 80 + "\n")
            for subject_id in sorted(clean_subjects):
                stats = subject_stats[subject_id]
                f.write(f"{subject_id}: {stats['ok']}/{stats['total_checks']} checks passed\n")
            f.write("\n")
        
        f.write("=" * 80 + "\n")
        f.write("END OF SUMMARY REPORT\n")
        f.write("=" * 80 + "\n")
    
    print(f"\n{'=' * 80}")
    print("SUMMARY REPORT GENERATED")
    print(f"{'=' * 80}")
    print(f"Report saved to: {output_path}")
    print(f"\nQuick Summary:")
    print(f"  - {len(problematic_subjects)} subject(s) need review")
    print(f"  - {len(clean_subjects)} subject(s) passed all checks")
    print(f"  - {total_errors} total error(s) found")
    print(f"\nProblematic subjects: {', '.join(sorted(problematic_subjects.keys())) if problematic_subjects else 'None'}")
    print(f"{'=' * 80}\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate summary report from diagnostic scan volume checks"
    )
    parser.add_argument(
        "--csv",
        required=True,
        help="Path to the diagnostic CSV file"
    )
    parser.add_argument(
        "--output-dir",
        required=True,
        help="Directory to save the summary report"
    )
    
    args = parser.parse_args()
    
    generate_summary(args.csv, args.output_dir)
