#!/bin/bash
# @Author: Shawn Schwartz - Stanford Memory Lab
# @Date: December 17, 2025
# @Description: Interactive setup for FSL GLM statistical analysis
# @Usage: ./setup_glm.sh

# Source configuration
source ../load_config.sh

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       FSL GLM Statistical Analysis Model Setup                ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Get model name from user
echo -e "${YELLOW}Enter a name for your GLM model (e.g., 'task-contrast-memory'):${NC}"
read -p "> " MODEL_NAME

if [ -z "$MODEL_NAME" ]; then
    echo -e "${YELLOW}Error: Model name cannot be empty${NC}"
    exit 1
fi

# Set studyid and basedir from config
STUDY_ID=$(basename "$BASE_DIR")
BASE_DIR_PARENT=$(dirname "$BASE_DIR")

echo ""
echo -e "${GREEN}Creating model directory structure...${NC}"
echo -e "  Study ID: ${STUDY_ID}"
echo -e "  Base directory: ${BASE_DIR_PARENT}"
echo -e "  Model name: ${MODEL_NAME}"
echo ""

# Call the Python setup script
python3 "$(dirname "$0")/setup.py" "$STUDY_ID" "$BASE_DIR_PARENT" "$MODEL_NAME"

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ Model setup complete!${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Configure model parameters in:"
    echo "   ${BASE_DIR}/model/level1/model-${MODEL_NAME}/model_params.json"
    echo ""
    echo "2. Define your experimental conditions in:"
    echo "   ${BASE_DIR}/model/level1/model-${MODEL_NAME}/condition_key.json"
    echo ""
    echo "3. (Optional) Define task contrasts in:"
    echo "   ${BASE_DIR}/model/level1/model-${MODEL_NAME}/task_contrasts.json"
    echo ""
    echo "4. Place your EV (explanatory variable) files in the onset directories"
    echo ""
    echo "5. Run level 1 analysis with: ./run_level1_glm.sh"
    echo ""
else
    echo -e "${YELLOW}Error: Model setup failed${NC}"
    exit 1
fi
