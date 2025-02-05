#!/bin/bash
# @Author: Shawn Schwartz - Stanford Memory Lab
# @Date: February 05, 2025
# @Description: Conveniently pull HTML and corresponding figures directories for fMRIPrep reports from your server to your local machine.

# Usage: ./pull_fmriprep_reports.sh username@server:/path/to/directory local_directory

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 username@server:/path/to/directory local_directory"
    echo "Example: $0 user@example.com:/data/project ./downloaded_data"
    exit 1
fi

SSH_SOURCE=$1
LOCAL_DIR=$2
SSH_HOST=${SSH_SOURCE%:*}

mkdir -p "$LOCAL_DIR"

# configure SSH multiplexing
SOCKET_DIR="/tmp/${USER}_ssh_mux"
mkdir -p "$SOCKET_DIR"
SOCKET_FILE="${SOCKET_DIR}/socket_%r@%h-%p"
SSH_OPTS="-o ControlMaster=auto -o ControlPath=${SOCKET_FILE} -o ControlPersist=10m"
SCP_OPTS="-o ControlMaster=auto -o ControlPath=${SOCKET_FILE} -o ControlPersist=10m"

# init master SSH connection
echo "($(date)) [INFO] Establishing SSH connection..."
ssh ${SSH_OPTS} ${SSH_HOST} "echo 'Connection established'"

# get list of subjects and their corresponding HTML files
echo "($(date)) [INFO] Getting list of files to download..."
SUBJECTS=$(ssh ${SSH_OPTS} ${SSH_HOST} "ls -1 ${SSH_SOURCE#*:} | grep '^sub-'")

for subject in $SUBJECTS; do
  # strip .html extension
  subject_id=${subject%.html}

  echo "($(date)) [INFO] Processing $subject_id..."
  mkdir -p "$LOCAL_DIR/$subject_id"
    
  # first download subject report html file
  scp ${SCP_OPTS} "$SSH_SOURCE/$subject_id.html" "$LOCAL_DIR/$subject_id.html"

  # then download the corresponding figures dir
  ssh ${SSH_OPTS} ${SSH_HOST} "[ -d ${SSH_SOURCE#*:}/$subject_id/figures ]" && \
  scp ${SCP_OPTS} -r "$SSH_SOURCE/$subject_id/figures" "$LOCAL_DIR/$subject_id"

  echo "($(date)) [INFO] Completed downloading $subject_id"
done

echo "($(date)) [INFO] Download complete! Files are in $LOCAL_DIR"

# clean up control socket
echo "($(date)) [INFO] Cleaning up SSH connection..."
ssh ${SSH_OPTS} -O exit ${SSH_HOST}

