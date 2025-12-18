#!/bin/bash
# Helper script to trigger a release
# Usage: ./trigger-release.sh [major|minor|patch]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if version type is provided
if [ $# -eq 0 ]; then
    echo -e "${RED}Error: Version bump type required${NC}"
    echo "Usage: $0 [major|minor|patch]"
    echo ""
    echo "Examples:"
    echo "  $0 patch    # Bug fixes (0.2.0 -> 0.2.1)"
    echo "  $0 minor    # New features (0.2.0 -> 0.3.0)"
    echo "  $0 major    # Breaking changes (0.2.0 -> 1.0.0)"
    exit 1
fi

BUMP_TYPE=$1

# Validate version bump type
if [[ ! "$BUMP_TYPE" =~ ^(major|minor|patch)$ ]]; then
    echo -e "${RED}Error: Invalid version bump type '$BUMP_TYPE'${NC}"
    echo "Must be one of: major, minor, patch"
    exit 1
fi

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Error: Not in a git repository${NC}"
    exit 1
fi

# Check if we're on main branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo -e "${YELLOW}Warning: You are on branch '$CURRENT_BRANCH', not 'main'${NC}"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo -e "${YELLOW}Warning: You have uncommitted changes${NC}"
    git status --short
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Get current version
CURRENT_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
echo -e "${GREEN}Current version: $CURRENT_TAG${NC}"

# Calculate next version
CURRENT_VERSION=${CURRENT_TAG#v}
IFS='.' read -r -a VERSION_PARTS <<< "$CURRENT_VERSION"
MAJOR="${VERSION_PARTS[0]:-0}"
MINOR="${VERSION_PARTS[1]:-0}"
PATCH="${VERSION_PARTS[2]:-0}"

case $BUMP_TYPE in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        ;;
    patch)
        PATCH=$((PATCH + 1))
        ;;
esac

NEXT_VERSION="$MAJOR.$MINOR.$PATCH"
echo -e "${GREEN}Next version: v$NEXT_VERSION${NC}"
echo ""

# Show commits since last tag
echo -e "${YELLOW}Commits since $CURRENT_TAG:${NC}"
if [ "$CURRENT_TAG" = "v0.0.0" ]; then
    git log --oneline --decorate | head -10
else
    git log ${CURRENT_TAG}..HEAD --oneline --decorate
fi
echo ""

# Confirm release
read -p "Create release v$NEXT_VERSION? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Release cancelled${NC}"
    exit 0
fi

# Create .release-ready file
echo "$BUMP_TYPE" > .release-ready
echo -e "${GREEN}Created .release-ready file with '$BUMP_TYPE'${NC}"

# Commit and push
git add .release-ready
git commit -m "chore: trigger v$NEXT_VERSION release"
echo -e "${GREEN}Committed release flag${NC}"

echo ""
echo -e "${YELLOW}Pushing to trigger release workflow...${NC}"
git push origin "$CURRENT_BRANCH"

echo ""
echo -e "${GREEN}✓ Release workflow triggered!${NC}"
echo ""
echo "Next steps:"
echo "1. Monitor the workflow at: https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\(.*\)\.git/\1/')/actions"
echo "2. The AI changelog-drafter agent will generate release notes"
echo "3. A new release will be created with version v$NEXT_VERSION"
echo "4. The .release-ready file will be automatically removed"
echo ""
echo -e "${GREEN}Done!${NC}"
