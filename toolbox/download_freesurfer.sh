#!/bin/bash
# @Author: Shawn Schwartz - Stanford Memory Lab
# @Date: December 17, 2025
# @Description: Download Freesurfer outputs from server for manual surface editing
# @Usage: ./download_freesurfer.sh [options]

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../load_config.sh"

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Freesurfer Output Download Utility                        ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Default values
REMOTE_SERVER=""
REMOTE_USER=""
REMOTE_BASE_DIR=""
LOCAL_DOWNLOAD_DIR="${HOME}/freesurfer_edits"
SUBJECTS_LIST=""
DOWNLOAD_ALL=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --server)
            REMOTE_SERVER="$2"
            shift 2
            ;;
        --user)
            REMOTE_USER="$2"
            shift 2
            ;;
        --remote-dir)
            REMOTE_BASE_DIR="$2"
            shift 2
            ;;
        --local-dir)
            LOCAL_DOWNLOAD_DIR="$2"
            shift 2
            ;;
        --subjects)
            SUBJECTS_LIST="$2"
            shift 2
            ;;
        --all)
            DOWNLOAD_ALL=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --server <hostname>        Remote server hostname (e.g., login.sherlock.stanford.edu)"
            echo "  --user <username>          Remote username"
            echo "  --remote-dir <path>        Remote base directory containing Freesurfer outputs"
            echo "  --local-dir <path>         Local directory to download to (default: ~/freesurfer_edits)"
            echo "  --subjects <file|list>     Subject list file or comma-separated subject IDs"
            echo "  --all                      Download all subjects"
            echo "  -h, --help                 Show this help message"
            echo ""
            echo "Interactive mode (no arguments):"
            echo "  Simply run without arguments to use interactive prompts"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Interactive mode if no arguments provided
if [ -z "$REMOTE_SERVER" ]; then
    echo -e "${YELLOW}Remote server hostname (e.g., login.sherlock.stanford.edu):${NC}"
    read -p "> " REMOTE_SERVER

    if [ -z "$REMOTE_SERVER" ]; then
        echo -e "${RED}Error: Server hostname is required${NC}"
        exit 1
    fi
fi

if [ -z "$REMOTE_USER" ]; then
    echo -e "${YELLOW}Remote username (SUNet ID):${NC}"
    read -p "> " REMOTE_USER

    if [ -z "$REMOTE_USER" ]; then
        echo -e "${RED}Error: Username is required${NC}"
        exit 1
    fi
fi

if [ -z "$REMOTE_BASE_DIR" ]; then
    echo -e "${YELLOW}Remote base directory (absolute path to BASE_DIR on server):${NC}"
    echo -e "${BLUE}(e.g., /oak/stanford/groups/yourlab/projects/yourstudy)${NC}"
    read -p "> " REMOTE_BASE_DIR

    if [ -z "$REMOTE_BASE_DIR" ]; then
        echo -e "${RED}Error: Remote base directory is required${NC}"
        exit 1
    fi
fi

# Construct remote Freesurfer directory path
REMOTE_FREESURFER_DIR="${REMOTE_BASE_DIR}/freesurfer"
# Escape path for safe use in remote shell
ESCAPED_REMOTE_FREESURFER_DIR=$(printf '%q' "$REMOTE_FREESURFER_DIR")

# Check if remote directory exists
echo ""
echo -e "${BLUE}Checking remote Freesurfer directory...${NC}"
if ! ssh "${REMOTE_USER}@${REMOTE_SERVER}" "[ -d '${ESCAPED_REMOTE_FREESURFER_DIR}' ]"; then
    echo -e "${RED}Error: Remote Freesurfer directory does not exist: ${REMOTE_FREESURFER_DIR}${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Remote directory found${NC}"

# Get subjects list
if [ "$DOWNLOAD_ALL" = true ]; then
    echo ""
    echo -e "${BLUE}Fetching all subjects from remote...${NC}"
    SUBJECTS=$(ssh "${REMOTE_USER}@${REMOTE_SERVER}" "ls -d ${REMOTE_FREESURFER_DIR}/sub-* 2>/dev/null | xargs -n 1 basename")

    if [ -z "$SUBJECTS" ]; then
        echo -e "${RED}Error: No subjects found in ${REMOTE_FREESURFER_DIR}${NC}"
        exit 1
    fi

    SUBJECT_COUNT=$(echo "$SUBJECTS" | wc -l)
    echo -e "${GREEN}Found ${SUBJECT_COUNT} subjects${NC}"
    echo ""
    echo "Subjects to download:"
    echo "$SUBJECTS" | head -10
    if [ "$SUBJECT_COUNT" -gt 10 ]; then
        echo "... and $((SUBJECT_COUNT - 10)) more"
    fi

elif [ -z "$SUBJECTS_LIST" ]; then
    echo ""
    echo -e "${YELLOW}Enter subjects to download:${NC}"
    echo -e "${BLUE}(Options: 'all', path to file, or comma-separated list like 'sub-001,sub-002')${NC}"
    read -p "> " SUBJECTS_INPUT

    if [ "$SUBJECTS_INPUT" = "all" ]; then
        SUBJECTS=$(ssh "${REMOTE_USER}@${REMOTE_SERVER}" "ls -d ${REMOTE_FREESURFER_DIR}/sub-* 2>/dev/null | xargs -n 1 basename")
    elif [ -f "$SUBJECTS_INPUT" ]; then
        # Read from file, filter comments and blank lines
        SUBJECTS=$(grep -v '^[[:space:]]*#' "$SUBJECTS_INPUT" | grep -v '^[[:space:]]*$' | cut -d: -f1)
    else
        # Treat as comma-separated list
        SUBJECTS=$(echo "$SUBJECTS_INPUT" | tr ',' '\n')
    fi
else
    if [ -f "$SUBJECTS_LIST" ]; then
        SUBJECTS=$(grep -v '^[[:space:]]*#' "$SUBJECTS_LIST" | grep -v '^[[:space:]]*$' | cut -d: -f1)
    else
        SUBJECTS=$(echo "$SUBJECTS_LIST" | tr ',' '\n')
    fi
fi

# Ensure subjects have sub- prefix
SUBJECTS=$(echo "$SUBJECTS" | sed 's/^sub-//' | sed 's/^/sub-/')

# Confirm download location
echo ""
echo -e "${YELLOW}Local download directory:${NC} ${LOCAL_DOWNLOAD_DIR}"
echo -e "${BLUE}Freesurfer outputs will be downloaded to this location for editing${NC}"
read -p "Is this correct? (Y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]]; then
    echo -e "${YELLOW}Please specify local download directory:${NC}"
    read -p "> " LOCAL_DOWNLOAD_DIR
fi

# Create local directory if it doesn't exist
mkdir -p "${LOCAL_DOWNLOAD_DIR}"

# Confirm before proceeding
echo ""
echo -e "${YELLOW}Ready to download Freesurfer outputs${NC}"
echo -e "  Remote: ${REMOTE_USER}@${REMOTE_SERVER}:${REMOTE_FREESURFER_DIR}"
echo -e "  Local:  ${LOCAL_DOWNLOAD_DIR}"
echo ""
read -p "Proceed with download? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Download cancelled${NC}"
    exit 0
fi

# Download subjects
echo ""
echo -e "${GREEN}Starting download...${NC}"
echo ""

SUCCESS_COUNT=0
FAIL_COUNT=0
FAILED_SUBJECTS=""

for subject in $SUBJECTS; do
    echo -e "${BLUE}Downloading ${subject}...${NC}"

    # Create subject directory
    mkdir -p "${LOCAL_DOWNLOAD_DIR}/${subject}"

    # Use rsync to download
    if rsync -avz --progress \
        "${REMOTE_USER}@${REMOTE_SERVER}:${REMOTE_FREESURFER_DIR}/${subject}/" \
        "${LOCAL_DOWNLOAD_DIR}/${subject}/"; then

        echo -e "${GREEN}✓ ${subject} downloaded successfully${NC}"
        ((SUCCESS_COUNT++))
    else
        echo -e "${RED}✗ Failed to download ${subject}${NC}"
        FAILED_SUBJECTS="${FAILED_SUBJECTS}\n  - ${subject}"
        ((FAIL_COUNT++))
    fi
    echo ""
done

# Summary
echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    Download Summary                            ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Successfully downloaded: ${SUCCESS_COUNT} subjects${NC}"
if [ $FAIL_COUNT -gt 0 ]; then
    echo -e "${RED}Failed to download: ${FAIL_COUNT} subjects${NC}"
    echo -e "${RED}Failed subjects:${FAILED_SUBJECTS}${NC}"
fi
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Edit Freesurfer surfaces in: ${LOCAL_DOWNLOAD_DIR}"
echo "2. Use Freeview or other tools to manually correct surfaces"
echo "3. After editing, upload back to server with: ./toolbox/upload_freesurfer.sh"
echo ""
echo -e "${BLUE}Common editing locations:${NC}"
echo "  - Brain mask: mri/brainmask.mgz"
echo "  - White matter surface: surf/lh.white, surf/rh.white"
echo "  - Pial surface: surf/lh.pial, surf/rh.pial"
echo "  - Control points: tmp/control.dat"
echo ""
echo -e "${GREEN}Download complete!${NC}"
