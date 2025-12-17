#!/bin/bash
# @Author: Shawn Schwartz - Stanford Memory Lab
# @Date: December 17, 2024
# @Description: Utility to tarball and untar subject sourcedata directories for inode optimization

# ============================================================================
# OVERVIEW
# ============================================================================
# This script provides utilities to:
# 1. Create tar archives of individual subject sourcedata directories
# 2. Extract tar archives back to sourcedata directories
#
# Primary goal: Reduce inode utilization on headless supercompute environments
# by archiving sourcedata directories into single tar files.
#
# ============================================================================
# USAGE
# ============================================================================
# Tarball operations:
#   ./tarball_sourcedata.sh --tar-all [--sourcedata-dir PATH]
#   ./tarball_sourcedata.sh --tar-subjects SUBJECT_LIST [--sourcedata-dir PATH]
#
# Untar operations:
#   ./tarball_sourcedata.sh --untar-all [--sourcedata-dir PATH]
#   ./tarball_sourcedata.sh --untar-subjects SUBJECT_LIST [--sourcedata-dir PATH]
#
# Arguments:
#   --tar-all              Tarball all subject directories found in sourcedata
#   --tar-subjects LIST    Tarball specific subjects (comma-separated or file path)
#   --untar-all            Extract all tar files found in sourcedata
#   --untar-subjects LIST  Extract specific subject tar files (comma-separated or file path)
#   --sourcedata-dir PATH  Path to sourcedata directory (default: current directory)
#   --output-dir PATH      Path to store tar files (default: sourcedata directory)
#   --keep-original        Keep original directory after tarballing (default: remove)
#   --help, -h             Show this help message
#
# Examples:
#   # Tarball all subjects in current directory
#   ./tarball_sourcedata.sh --tar-all
#
#   # Tarball specific subjects
#   ./tarball_sourcedata.sh --tar-subjects "001,002,003"
#   ./tarball_sourcedata.sh --tar-subjects subjects.txt
#
#   # Tarball subjects with custom sourcedata directory
#   ./tarball_sourcedata.sh --tar-all --sourcedata-dir /path/to/project/sourcedata
#
#   # Untar all subjects
#   ./tarball_sourcedata.sh --untar-all
#
#   # Untar specific subjects
#   ./tarball_sourcedata.sh --untar-subjects "001,002"
#   ./tarball_sourcedata.sh --untar-subjects subjects.txt
#
# ============================================================================

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
SOURCEDATA_DIR="."
OUTPUT_DIR=""
KEEP_ORIGINAL=false
OPERATION=""
SUBJECT_LIST=""

# ============================================================================
# FUNCTION: print_usage
# ============================================================================
print_usage() {
  cat << EOF
Sourcedata Tarball Utility
==========================

DESCRIPTION:
  Utility to create and extract tar archives of subject sourcedata directories.
  Helps reduce inode utilization on supercompute environments.

USAGE:
  Tarball operations:
    $0 --tar-all [OPTIONS]
    $0 --tar-subjects SUBJECT_LIST [OPTIONS]

  Untar operations:
    $0 --untar-all [OPTIONS]
    $0 --untar-subjects SUBJECT_LIST [OPTIONS]

ARGUMENTS:
  --tar-all              Tarball all subject directories in sourcedata
  --tar-subjects LIST    Tarball specific subjects (comma-separated or file path)
  --untar-all            Extract all tar files in sourcedata
  --untar-subjects LIST  Extract specific subject tar files (comma-separated or file path)
  --sourcedata-dir PATH  Path to sourcedata directory (default: current directory)
  --output-dir PATH      Path to store tar files (default: sourcedata directory)
  --keep-original        Keep original directory after tarballing (default: remove)
  --help, -h             Show this help message

EXAMPLES:
  # Tarball all subjects
  $0 --tar-all

  # Tarball specific subjects from comma-separated list
  $0 --tar-subjects "001,002,003"

  # Tarball subjects from file
  $0 --tar-subjects all-subjects.txt

  # Tarball with custom directories
  $0 --tar-all --sourcedata-dir /path/to/sourcedata --output-dir /path/to/tarballs

  # Tarball but keep original directories
  $0 --tar-all --keep-original

  # Untar all subjects
  $0 --untar-all

  # Untar specific subjects
  $0 --untar-subjects "001,002"

EOF
}

# ============================================================================
# FUNCTION: log_message
# ============================================================================
log_message() {
  local level=$1
  shift
  local message="$@"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  
  case $level in
    "INFO")
      echo -e "${BLUE}[INFO]${NC} (${timestamp}) ${message}"
      ;;
    "SUCCESS")
      echo -e "${GREEN}[SUCCESS]${NC} (${timestamp}) ${message}"
      ;;
    "WARNING")
      echo -e "${YELLOW}[WARNING]${NC} (${timestamp}) ${message}"
      ;;
    "ERROR")
      echo -e "${RED}[ERROR]${NC} (${timestamp}) ${message}"
      ;;
  esac
}

# ============================================================================
# FUNCTION: parse_subject_list
# ============================================================================
parse_subject_list() {
  local input=$1
  local subjects=()
  
  # Check if input is a file
  if [ -f "$input" ]; then
    log_message "INFO" "Reading subjects from file: $input" >&2
    while IFS= read -r line || [ -n "$line" ]; do
      # Skip empty lines and comments
      [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
      # Remove leading/trailing whitespace
      line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
      [ -n "$line" ] && subjects+=("$line")
    done < "$input"
  else
    # Treat as comma-separated list
    IFS=',' read -ra subjects <<< "$input"
    # Trim whitespace from each subject
    for i in "${!subjects[@]}"; do
      subjects[$i]=$(echo "${subjects[$i]}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    done
  fi
  
  echo "${subjects[@]}"
}

# ============================================================================
# FUNCTION: get_all_subjects
# ============================================================================
get_all_subjects() {
  local sourcedata_dir=$1
  local subjects=()
  
  # Find all directories matching sub-* pattern
  for dir in "$sourcedata_dir"/sub-*; do
    if [ -d "$dir" ]; then
      # Extract subject ID (remove "sub-" prefix)
      local subj=$(basename "$dir" | sed 's/^sub-//')
      subjects+=("$subj")
    fi
  done
  
  echo "${subjects[@]}"
}

# ============================================================================
# FUNCTION: tarball_subject
# ============================================================================
tarball_subject() {
  local subject_id=$1
  local sourcedata_dir=$2
  local output_dir=$3
  local keep_original=$4
  
  local subject_dir="${sourcedata_dir}/sub-${subject_id}"
  local tar_file="${output_dir}/sub-${subject_id}.tar"
  
  # Check if subject directory exists
  if [ ! -d "$subject_dir" ]; then
    log_message "ERROR" "Subject directory not found: $subject_dir"
    return 1
  fi
  
  # Check if tar file already exists
  if [ -f "$tar_file" ]; then
    log_message "WARNING" "Tar file already exists: $tar_file (skipping)"
    return 0
  fi
  
  log_message "INFO" "Creating tarball for sub-${subject_id}..."
  
  # Create tar file
  # Use -C to change directory so tar doesn't include full path
  local tar_stderr=$(mktemp)
  if tar -cf "$tar_file" -C "$sourcedata_dir" "sub-${subject_id}" 2>"$tar_stderr"; then
    rm -f "$tar_stderr"
    local tar_size=$(du -h "$tar_file" | cut -f1)
    log_message "SUCCESS" "Created tarball: $tar_file (${tar_size})"
    
    # Remove original directory if requested
    if [ "$keep_original" = false ]; then
      log_message "INFO" "Removing original directory: $subject_dir"
      if rm -rf "$subject_dir"; then
        log_message "SUCCESS" "Removed original directory: $subject_dir"
      else
        log_message "ERROR" "Failed to remove directory: $subject_dir"
        return 1
      fi
    fi
    
    return 0
  else
    log_message "ERROR" "Failed to create tarball for sub-${subject_id}"
    if [ -s "$tar_stderr" ]; then
      log_message "ERROR" "Tar error: $(cat "$tar_stderr")"
    fi
    rm -f "$tar_stderr"
    return 1
  fi
}

# ============================================================================
# FUNCTION: untar_subject
# ============================================================================
untar_subject() {
  local subject_id=$1
  local sourcedata_dir=$2
  local tar_dir=$3
  
  local subject_dir="${sourcedata_dir}/sub-${subject_id}"
  local tar_file="${tar_dir}/sub-${subject_id}.tar"
  
  # Check if tar file exists
  if [ ! -f "$tar_file" ]; then
    log_message "ERROR" "Tar file not found: $tar_file"
    return 1
  fi
  
  # Check if subject directory already exists
  if [ -d "$subject_dir" ]; then
    log_message "WARNING" "Subject directory already exists: $subject_dir (skipping)"
    return 0
  fi
  
  log_message "INFO" "Extracting tarball for sub-${subject_id}..."
  
  # Extract tar file
  local tar_stderr=$(mktemp)
  if tar -xf "$tar_file" -C "$sourcedata_dir" 2>"$tar_stderr"; then
    rm -f "$tar_stderr"
    log_message "SUCCESS" "Extracted tarball to: $subject_dir"
    
    # Verify extraction
    if [ -d "$subject_dir" ]; then
      local dir_size=$(du -sh "$subject_dir" | cut -f1)
      log_message "SUCCESS" "Verified directory: $subject_dir (${dir_size})"
      return 0
    else
      log_message "ERROR" "Directory not found after extraction: $subject_dir"
      return 1
    fi
  else
    log_message "ERROR" "Failed to extract tarball for sub-${subject_id}"
    if [ -s "$tar_stderr" ]; then
      log_message "ERROR" "Tar error: $(cat "$tar_stderr")"
    fi
    rm -f "$tar_stderr"
    return 1
  fi
}

# ============================================================================
# FUNCTION: tarball_subjects
# ============================================================================
tarball_subjects() {
  local subjects=("$@")
  local total=${#subjects[@]}
  local success=0
  local failed=0
  local skipped=0
  
  log_message "INFO" "Starting tarball operation for ${total} subject(s)..."
  
  for subject in "${subjects[@]}"; do
    if tarball_subject "$subject" "$SOURCEDATA_DIR" "$OUTPUT_DIR" "$KEEP_ORIGINAL"; then
      ((success++))
    else
      # Check if it was skipped (tar already exists)
      if [ -f "${OUTPUT_DIR}/sub-${subject}.tar" ]; then
        ((skipped++))
      else
        ((failed++))
      fi
    fi
  done
  
  log_message "INFO" "=========================================="
  log_message "INFO" "Tarball operation complete!"
  log_message "INFO" "Total subjects: ${total}"
  log_message "SUCCESS" "Successfully tarballed: ${success}"
  [ $skipped -gt 0 ] && log_message "WARNING" "Skipped (already exists): ${skipped}"
  [ $failed -gt 0 ] && log_message "ERROR" "Failed: ${failed}"
  log_message "INFO" "=========================================="
  
  return $failed
}

# ============================================================================
# FUNCTION: untar_subjects
# ============================================================================
untar_subjects() {
  local subjects=("$@")
  local total=${#subjects[@]}
  local success=0
  local failed=0
  local skipped=0
  
  log_message "INFO" "Starting untar operation for ${total} subject(s)..."
  
  for subject in "${subjects[@]}"; do
    if untar_subject "$subject" "$SOURCEDATA_DIR" "$OUTPUT_DIR"; then
      ((success++))
    else
      # Check if it was skipped (directory already exists)
      if [ -d "${SOURCEDATA_DIR}/sub-${subject}" ]; then
        ((skipped++))
      else
        ((failed++))
      fi
    fi
  done
  
  log_message "INFO" "=========================================="
  log_message "INFO" "Untar operation complete!"
  log_message "INFO" "Total subjects: ${total}"
  log_message "SUCCESS" "Successfully extracted: ${success}"
  [ $skipped -gt 0 ] && log_message "WARNING" "Skipped (already exists): ${skipped}"
  [ $failed -gt 0 ] && log_message "ERROR" "Failed: ${failed}"
  log_message "INFO" "=========================================="
  
  return $failed
}

# ============================================================================
# MAIN SCRIPT
# ============================================================================

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --tar-all)
      OPERATION="tar-all"
      shift
      ;;
    --tar-subjects)
      OPERATION="tar-subjects"
      SUBJECT_LIST="$2"
      shift 2
      ;;
    --untar-all)
      OPERATION="untar-all"
      shift
      ;;
    --untar-subjects)
      OPERATION="untar-subjects"
      SUBJECT_LIST="$2"
      shift 2
      ;;
    --sourcedata-dir)
      SOURCEDATA_DIR="$2"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --keep-original)
      KEEP_ORIGINAL=true
      shift
      ;;
    --help|-h)
      print_usage
      exit 0
      ;;
    *)
      log_message "ERROR" "Unknown option: $1"
      print_usage
      exit 1
      ;;
  esac
done

# Validate operation is specified
if [ -z "$OPERATION" ]; then
  log_message "ERROR" "No operation specified. Use --tar-all, --tar-subjects, --untar-all, or --untar-subjects"
  print_usage
  exit 1
fi

# Resolve absolute paths
SOURCEDATA_DIR=$(realpath "$SOURCEDATA_DIR")

# Set output directory to sourcedata directory if not specified
if [ -z "$OUTPUT_DIR" ]; then
  OUTPUT_DIR="$SOURCEDATA_DIR"
else
  OUTPUT_DIR=$(realpath "$OUTPUT_DIR")
fi

# Validate sourcedata directory exists
if [ ! -d "$SOURCEDATA_DIR" ]; then
  log_message "ERROR" "Sourcedata directory not found: $SOURCEDATA_DIR"
  exit 1
fi

# Create output directory if it doesn't exist (for tar operations)
if [[ "$OPERATION" == tar-* ]]; then
  mkdir -p "$OUTPUT_DIR"
fi

log_message "INFO" "Sourcedata directory: $SOURCEDATA_DIR"
log_message "INFO" "Output directory: $OUTPUT_DIR"

# Execute operation
case $OPERATION in
  tar-all)
    subjects=($(get_all_subjects "$SOURCEDATA_DIR"))
    if [ ${#subjects[@]} -eq 0 ]; then
      log_message "ERROR" "No subject directories found in $SOURCEDATA_DIR"
      exit 1
    fi
    log_message "INFO" "Found ${#subjects[@]} subject(s) to tarball"
    tarball_subjects "${subjects[@]}"
    exit $?
    ;;
  
  tar-subjects)
    if [ -z "$SUBJECT_LIST" ]; then
      log_message "ERROR" "No subject list provided for --tar-subjects"
      exit 1
    fi
    subjects=($(parse_subject_list "$SUBJECT_LIST"))
    if [ ${#subjects[@]} -eq 0 ]; then
      log_message "ERROR" "No subjects found in list: $SUBJECT_LIST"
      exit 1
    fi
    log_message "INFO" "Tarballing ${#subjects[@]} subject(s)"
    tarball_subjects "${subjects[@]}"
    exit $?
    ;;
  
  untar-all)
    # Find all tar files in output directory
    subjects=()
    for tar_file in "$OUTPUT_DIR"/sub-*.tar; do
      if [ -f "$tar_file" ]; then
        # Extract subject ID from tar filename
        subj=$(basename "$tar_file" .tar | sed 's/^sub-//')
        subjects+=("$subj")
      fi
    done
    if [ ${#subjects[@]} -eq 0 ]; then
      log_message "ERROR" "No tar files found in $OUTPUT_DIR"
      exit 1
    fi
    log_message "INFO" "Found ${#subjects[@]} tar file(s) to extract"
    untar_subjects "${subjects[@]}"
    exit $?
    ;;
  
  untar-subjects)
    if [ -z "$SUBJECT_LIST" ]; then
      log_message "ERROR" "No subject list provided for --untar-subjects"
      exit 1
    fi
    subjects=($(parse_subject_list "$SUBJECT_LIST"))
    if [ ${#subjects[@]} -eq 0 ]; then
      log_message "ERROR" "No subjects found in list: $SUBJECT_LIST"
      exit 1
    fi
    log_message "INFO" "Extracting ${#subjects[@]} subject(s)"
    untar_subjects "${subjects[@]}"
    exit $?
    ;;
esac
