#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to display usage
usage() {
  echo "Usage: $0 <version_type>"
  echo ""
  echo "Version types:"
  echo "  patch  - Bump patch version (0.1.0 -> 0.1.1)"
  echo "  minor  - Bump minor version (0.1.0 -> 0.2.0)"
  echo "  major  - Bump major version (0.1.0 -> 1.0.0)"
  echo "  x.y.z  - Set specific version (e.g., 1.2.3)"
  echo ""
  echo "Examples:"
  echo "  $0 patch"
  echo "  $0 minor"
  echo "  $0 1.2.3"
  exit 1
}

# Check if version type is provided
if [ -z "$1" ]; then
  echo -e "${RED}Error: Version type is required${NC}"
  usage
fi

VERSION_TYPE=$1

# Files to update
VERSION_FILE="lib/skit/version.rb"
GEMFILE_LOCK="Gemfile.lock"

# Check if files exist
if [ ! -f "$VERSION_FILE" ]; then
  echo -e "${RED}Error: $VERSION_FILE not found${NC}"
  exit 1
fi

if [ ! -f "$GEMFILE_LOCK" ]; then
  echo -e "${RED}Error: $GEMFILE_LOCK not found${NC}"
  exit 1
fi

# Get current version from version.rb
CURRENT_VERSION=$(grep -E '^\s*VERSION\s*=\s*"[0-9]+\.[0-9]+\.[0-9]+"' "$VERSION_FILE" | sed -E 's/.*"([0-9]+\.[0-9]+\.[0-9]+)".*/\1/')

if [ -z "$CURRENT_VERSION" ]; then
  echo -e "${RED}Error: Could not find current version in $VERSION_FILE${NC}"
  exit 1
fi

echo -e "${GREEN}Current version: $CURRENT_VERSION${NC}"

# Parse version components
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

# Calculate new version
case $VERSION_TYPE in
  patch)
    NEW_VERSION="$MAJOR.$MINOR.$((PATCH + 1))"
    ;;
  minor)
    NEW_VERSION="$MAJOR.$((MINOR + 1)).0"
    ;;
  major)
    NEW_VERSION="$((MAJOR + 1)).0.0"
    ;;
  [0-9]*.[0-9]*.[0-9]*)
    NEW_VERSION=$VERSION_TYPE
    ;;
  *)
    echo -e "${RED}Error: Invalid version type '$VERSION_TYPE'${NC}"
    usage
    ;;
esac

echo -e "${YELLOW}New version: $NEW_VERSION${NC}"
echo ""

# Confirm with user
read -p "Do you want to update the version? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo -e "${RED}Aborted${NC}"
  exit 1
fi

# Update version.rb
echo "Updating $VERSION_FILE..."
sed -i.bak "s/VERSION = \"$CURRENT_VERSION\"/VERSION = \"$NEW_VERSION\"/" "$VERSION_FILE"
rm "${VERSION_FILE}.bak"

# Update Gemfile.lock
echo "Updating $GEMFILE_LOCK..."
sed -i.bak "s/skit ($CURRENT_VERSION)/skit ($NEW_VERSION)/" "$GEMFILE_LOCK"
rm "${GEMFILE_LOCK}.bak"

echo -e "${GREEN}Version updated successfully!${NC}"
echo ""
echo "Next steps:"
echo "  1. Review changes: git diff"
echo "  2. Commit changes: git add $VERSION_FILE $GEMFILE_LOCK && git commit -m \"chore: bump version to $NEW_VERSION\""
echo "  3. Create tag: git tag v$NEW_VERSION"
echo "  4. Push changes: git push origin main --tags"
