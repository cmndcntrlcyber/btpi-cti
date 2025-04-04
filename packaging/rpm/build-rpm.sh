#!/bin/bash
#
# BTPI-CTI RPM Package Build Script
# This script builds an RPM package for the Blue Team Portable Infrastructure - Cyber Threat Intelligence
#

set -e

# Configuration
PACKAGE_NAME="btpi-cti"
PACKAGE_VERSION="1.0.0"
SPEC_FILE="btpi-cti.spec"
SOURCE_DIR="../.."
BUILD_DIR="./rpmbuild"

# Display banner
echo "====================================================="
echo "  BTPI-CTI RPM Package Build"
echo "====================================================="
echo ""

# Check if rpmbuild is installed
if ! command -v rpmbuild &> /dev/null; then
    echo "Error: rpmbuild is not installed or not in PATH"
    echo "Please install the rpm-build package:"
    echo "  For RHEL/CentOS/Fedora: sudo dnf install rpm-build"
    echo "  For Ubuntu/Debian: sudo apt-get install rpm"
    exit 1
fi

# Parse command line arguments
VERSION=""

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -v|--version)
            VERSION="$2"
            shift
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  -v, --version VERSION    Set the package version (default: 1.0.0)"
            echo "  -h, --help               Display this help message"
            echo ""
            exit 0
            ;;
        *)
            echo "Unknown option: $key"
            echo "Use --help to see available options"
            exit 1
            ;;
    esac
done

# Set version if provided
if [ ! -z "$VERSION" ]; then
    PACKAGE_VERSION="$VERSION"
    # Update version in spec file
    sed -i "s/^Version:.*/Version:        $PACKAGE_VERSION/" "$SPEC_FILE"
fi

# Create RPM build directory structure
echo "Creating RPM build directory structure..."
mkdir -p "$BUILD_DIR"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

# Create source tarball
echo "Creating source tarball..."
SOURCE_TARBALL="$BUILD_DIR/SOURCES/$PACKAGE_NAME-$PACKAGE_VERSION.tar.gz"
(cd "$SOURCE_DIR" && tar --exclude='.git' --exclude='packaging/rpm/rpmbuild' -czf "$SOURCE_TARBALL" .)

# Copy spec file
echo "Copying spec file..."
cp "$SPEC_FILE" "$BUILD_DIR/SPECS/"

# Build RPM package
echo "Building RPM package..."
rpmbuild --define "_topdir $(pwd)/$BUILD_DIR" -ba "$BUILD_DIR/SPECS/$SPEC_FILE"

# Find the built RPM
RPM_PATH=$(find "$BUILD_DIR/RPMS" -name "*.rpm" | head -n 1)

if [ -f "$RPM_PATH" ]; then
    echo ""
    echo "RPM package built successfully: $RPM_PATH"
    
    # Copy RPM to current directory
    cp "$RPM_PATH" .
    FINAL_RPM=$(basename "$RPM_PATH")
    
    echo "Copied to: $(pwd)/$FINAL_RPM"
    echo ""
    echo "To install the package:"
    echo "  sudo rpm -ivh $FINAL_RPM"
    echo ""
    echo "To upgrade an existing installation:"
    echo "  sudo rpm -Uvh $FINAL_RPM"
else
    echo ""
    echo "Error: RPM package build failed"
    exit 1
fi

echo ""
echo "====================================================="
echo "  Build Complete"
echo "====================================================="
echo ""

exit 0
