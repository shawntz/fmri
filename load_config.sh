#!/bin/bash
# ============================================================================
# Configuration Loader for fMRI Preprocessing Pipeline
# ============================================================================
#
# This script loads configuration from config.yaml and exports environment
# variables that can be used throughout the preprocessing pipeline.
#
# USAGE:
#   source ./load_config.sh
#
# NOTE: This script must be sourced, not executed, to properly export
# environment variables to the calling shell.
# ============================================================================

# Get the directory where this script resides
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_YAML_CONFIG_FILE="${SCRIPT_DIR}/config.yaml"

# Check if config file exists
if [ ! -f "${_YAML_CONFIG_FILE}" ]; then
    echo "ERROR: Configuration file not found: ${_YAML_CONFIG_FILE}"
    echo "Please copy config.template.yaml to config.yaml and configure it for your study."
    return 1 2>/dev/null || exit 1
fi

# Parse YAML and export environment variables using Python
eval "$(_YAML_CONFIG_FILE="${_YAML_CONFIG_FILE}" python3 - <<'EOF'
import yaml
import sys
import os

def expand_var(value, env_vars):
    """Expand environment variables in string values."""
    if not isinstance(value, str):
        return value
    
    # Replace ${VAR} or $VAR with actual values
    import re
    def replace_var(match):
        var_name = match.group(1) if match.group(1) else match.group(2)
        # First check our accumulated env_vars, then fall back to os.environ
        return env_vars.get(var_name, os.environ.get(var_name, match.group(0)))
    
    # Handle both ${VAR} and $VAR formats
    result = re.sub(r'\$\{([^}]+)\}|\$([A-Za-z_][A-Za-z0-9_]*)', replace_var, value)
    return result

def flatten_dict(d, parent_key='', sep='_', env_vars=None):
    """Flatten nested dictionary and convert keys to uppercase environment variable names."""
    if env_vars is None:
        env_vars = {}
    
    items = []
    for k, v in d.items():
        # Convert key to uppercase for environment variable
        new_key = f"{parent_key}{sep}{k}".upper() if parent_key else k.upper()
        
        if isinstance(v, dict):
            # Recursively flatten nested dictionaries
            items.extend(flatten_dict(v, new_key, sep=sep, env_vars=env_vars).items())
        elif isinstance(v, list):
            # Handle lists (like run_numbers)
            # Store as space-separated string for bash arrays
            expanded_items = [expand_var(str(item), env_vars) for item in v]
            env_vars[new_key] = ' '.join(expanded_items)
            items.append((new_key, env_vars[new_key]))
        else:
            # Expand any variables in the value
            expanded_value = expand_var(str(v), env_vars)
            env_vars[new_key] = expanded_value
            items.append((new_key, expanded_value))
    
    return dict(items)

try:
    # Read and parse YAML config - always use the _YAML_CONFIG_FILE env var set by the shell
    config_path = os.environ.get('_YAML_CONFIG_FILE', 'config.yaml')
    with open(config_path, 'r') as f:
        config = yaml.safe_load(f)
    
    # Flatten the configuration
    env_vars = flatten_dict(config)
    
    # Add special aliases for commonly used variables to maintain compatibility
    # Map new names to old names
    aliases = {
        'BASE_DIR': 'DIRECTORIES_BASE_DIR',
        'SCRIPTS_DIR': 'DIRECTORIES_SCRIPTS_DIR',
        'RAW_DIR': 'DIRECTORIES_RAW_DIR',
        'TRIM_DIR': 'DIRECTORIES_TRIM_DIR',
        'WORKFLOW_LOG_DIR': 'DIRECTORIES_WORKFLOW_LOG_DIR',
        'TEMPLATEFLOW_HOST_HOME': 'DIRECTORIES_TEMPLATEFLOW_HOST_HOME',
        'FMRIPREP_HOST_CACHE': 'DIRECTORIES_FMRIPREP_HOST_CACHE',
        'FREESURFER_LICENSE': 'DIRECTORIES_FREESURFER_LICENSE',
        'USER_EMAIL': 'USER_EMAIL',
        'USER': 'USER_USERNAME',
        'FW_GROUP_ID': 'USER_FW_GROUP_ID',
        'FW_PROJECT_ID': 'USER_FW_PROJECT_ID',
        'FW_CLI_API_KEY_FILE': 'SCAN_FW_CLI_API_KEY_FILE',
        'FW_URL': 'SCAN_FW_URL',
        'CONFIG_FILE': 'SCAN_CONFIG_FILE',
        'EXPERIMENT_TYPE': 'SCAN_EXPERIMENT_TYPE',
        'task_id': 'SCAN_TASK_ID',
        'new_task_id': 'SCAN_NEW_TASK_ID',
        'n_dummy': 'SCAN_N_DUMMY',
        'run_numbers': 'SCAN_RUN_NUMBERS',
        'EXPECTED_FMAP_VOLS': 'VALIDATION_EXPECTED_FMAP_VOLS',
        'EXPECTED_BOLD_VOLS': 'VALIDATION_EXPECTED_BOLD_VOLS',
        'EXPECTED_BOLD_VOLS_AFTER_TRIMMING': 'VALIDATION_EXPECTED_BOLD_VOLS_AFTER_TRIMMING',
        'DIR_PERMISSIONS': 'PERMISSIONS_DIR_PERMISSIONS',
        'FILE_PERMISSIONS': 'PERMISSIONS_FILE_PERMISSIONS',
        'SLURM_EMAIL': 'SLURM_EMAIL',
        'SLURM_TIME': 'SLURM_TIME',
        'DCMNIIX_SLURM_TIME': 'SLURM_DCMNIIX_TIME',
        'SLURM_MEM': 'SLURM_MEM',
        'SLURM_CPUS': 'SLURM_CPUS',
        'SLURM_ARRAY_THROTTLE': 'SLURM_ARRAY_THROTTLE',
        'SLURM_LOG_DIR': 'SLURM_LOG_DIR',
        'SLURM_PARTITION': 'SLURM_PARTITION',
        'FMRIPREP_VERSION': 'PIPELINE_FMRIPREP_VERSION',
        'DERIVS_DIR': 'PIPELINE_DERIVS_DIR',
        'SINGULARITY_IMAGE_DIR': 'PIPELINE_SINGULARITY_IMAGE_DIR',
        'SINGULARITY_IMAGE': 'PIPELINE_SINGULARITY_IMAGE',
        'HEUDICONV_IMAGE': 'PIPELINE_HEUDICONV_IMAGE',
        'FMRIPREP_SLURM_JOB_NAME': 'FMRIPREP_SLURM_JOB_NAME',
        'FMRIPREP_SLURM_ARRAY_SIZE': 'FMRIPREP_SLURM_ARRAY_SIZE',
        'FMRIPREP_SLURM_TIME': 'FMRIPREP_SLURM_TIME',
        'FMRIPREP_SLURM_CPUS_PER_TASK': 'FMRIPREP_SLURM_CPUS_PER_TASK',
        'FMRIPREP_SLURM_MEM_PER_CPU': 'FMRIPREP_SLURM_MEM_PER_CPU',
        'FMRIPREP_OMP_THREADS': 'FMRIPREP_OMP_THREADS',
        'FMRIPREP_NTHREADS': 'FMRIPREP_NTHREADS',
        'FMRIPREP_MEM_MB': 'FMRIPREP_MEM_MB',
        'FMRIPREP_FD_SPIKE_THRESHOLD': 'FMRIPREP_FD_SPIKE_THRESHOLD',
        'FMRIPREP_DVARS_SPIKE_THRESHOLD': 'FMRIPREP_DVARS_SPIKE_THRESHOLD',
        'FMRIPREP_OUTPUT_SPACES': 'FMRIPREP_OUTPUT_SPACES',
        'DEBUG': 'MISC_DEBUG',
    }
    
    # Expand variables in aliased values
    expanded_env_vars = {}
    for alias, source in aliases.items():
        if source in env_vars:
            value = env_vars[source]
            # Perform additional expansion with already-set aliases
            expanded_value = expand_var(value, expanded_env_vars)
            expanded_env_vars[alias] = expanded_value
    
    # Merge expanded aliases back
    env_vars.update(expanded_env_vars)
    
    # Output export statements for bash to evaluate
    for key, value in env_vars.items():
        # Escape single quotes in values
        escaped_value = value.replace("'", "'\\''")
        print(f"export {key}='{escaped_value}'")
    
except FileNotFoundError:
    print("echo 'ERROR: config.yaml not found'", file=sys.stderr)
    sys.exit(1)
except yaml.YAMLError as e:
    print(f"echo 'ERROR: Failed to parse config.yaml: {e}'", file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f"echo 'ERROR: {e}'", file=sys.stderr)
    sys.exit(1)
EOF
)"

# Parse fmap_mapping from YAML into bash associative array
eval "$(_YAML_CONFIG_FILE="${_YAML_CONFIG_FILE}" python3 - <<'EOF'
import yaml
import os

try:
    config_path = os.environ.get('_YAML_CONFIG_FILE', 'config.yaml')
    with open(config_path, 'r') as f:
        config = yaml.safe_load(f)
    
    if 'fmap_mapping' in config:
        print("declare -gA fmap_mapping=(")
        for key, value in config['fmap_mapping'].items():
            print(f'    ["{key}"]="{value}"')
        print(")")
except Exception as e:
    print(f"echo 'ERROR loading fmap_mapping: {e}'", file=sys.stderr)
    exit(1)
EOF
)"

# Convert run_numbers from space-separated string to bash array
if [ -n "${run_numbers}" ]; then
    read -ra run_numbers <<< "${run_numbers}"
    export run_numbers
fi

# Interactive prompt to choose which subjects file to use (matching original settings.sh behavior)
select_subjects_file() {
    local step_num=""
    local subjects_file="all-subjects.txt"
    local custom_file=""
    
    # only prompt if being sourced in an interactive shell
    if [[ -t 0 ]]; then
        echo "Select subjects file to use:"
        echo "1) Use all-subjects.txt (default)"
        echo "2) Use step-specific subjects file (e.g., 04-subjects.txt)"
        read -p "Enter choice [1/2]: " choice
        
        if [[ "$choice" == "2" ]]; then
            read -p "Enter step number (e.g., 04): " step_num
            custom_file="${step_num}-subjects.txt"
            
            if [[ -f "$custom_file" ]]; then
                subjects_file="$custom_file"
                echo "Using $subjects_file"
            else
                echo "Warning: $custom_file not found. Falling back to all-subjects.txt"
            fi
        fi
    fi
    
    # calculate number of subjects based on selected file
    if [[ -f "$subjects_file" ]]; then
        num_subjects=$(wc -l < "$subjects_file")
        echo "($(date)) [INFO] Found ${num_subjects} total subjects in $subjects_file"
        array_range="0-$((num_subjects-1))"
    else
        echo "($(date)) [WARNING] $subjects_file not found, defaulting to single subject"
        num_subjects=1
        array_range="0"
    fi

    export SELECTED_SUBJECTS_FILE="$subjects_file"
    export SLURM_ARRAY_SIZE="${array_range}"
}

# Run the function to set up the variables
select_subjects_file

echo "($(date)) [INFO] Configuration loaded successfully from ${_YAML_CONFIG_FILE}"
