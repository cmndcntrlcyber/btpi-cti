#!/bin/bash
#
# BTPI-CTI Debian Package Build Script
# This script builds a Debian package for the Blue Team Portable Infrastructure - Cyber Threat Intelligence
#

set -e

# Configuration
PACKAGE_NAME="btpi-cti"
PACKAGE_VERSION="1.0.0"
SOURCE_DIR="../.."
BUILD_DIR="./build"
INSTALL_DIR="$BUILD_DIR/opt/btpi-cti"

# Display banner
echo "====================================================="
echo "  BTPI-CTI Debian Package Build"
echo "====================================================="
echo ""

# Check if dpkg-deb is installed
if ! command -v dpkg-deb &> /dev/null; then
    echo "Error: dpkg-deb is not installed or not in PATH"
    echo "Please install the dpkg-dev package:"
    echo "  sudo apt-get install dpkg-dev"
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
    # Update version in control file
    sed -i "s/^Version:.*/Version: $PACKAGE_VERSION/" "DEBIAN/control"
fi

# Create build directory structure
echo "Creating build directory structure..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$BUILD_DIR/etc/btpi-cti"
mkdir -p "$BUILD_DIR/var/log/btpi-cti"
mkdir -p "$BUILD_DIR/usr/local/bin"

# Copy DEBIAN directory
echo "Copying DEBIAN directory..."
cp -r DEBIAN "$BUILD_DIR/"

# Copy source files
echo "Copying source files..."
(cd "$SOURCE_DIR" && find . -type f -not -path "*/\.*" -not -path "*/packaging/*" -exec cp --parents {} "$INSTALL_DIR/" \;)

# Create symlinks
echo "Creating symlinks..."
ln -sf /opt/btpi-cti/deploy.sh "$BUILD_DIR/usr/local/bin/deploy-cti"
ln -sf /opt/btpi-cti/cti-manage.sh "$BUILD_DIR/usr/local/bin/cti-manage"
ln -sf /opt/btpi-cti/scripts/backup.sh "$BUILD_DIR/usr/local/bin/cti-backup"
ln -sf /opt/btpi-cti/scripts/restore.sh "$BUILD_DIR/usr/local/bin/cti-restore"
ln -sf /opt/btpi-cti/scripts/health-check.sh "$BUILD_DIR/usr/local/bin/cti-health-check"
ln -sf /opt/btpi-cti/scripts/update.sh "$BUILD_DIR/usr/local/bin/cti-update"

# Set permissions
echo "Setting permissions..."
find "$BUILD_DIR" -type f -name "*.sh" -exec chmod 755 {} \;
chmod 755 "$BUILD_DIR/DEBIAN/postinst"
chmod 755 "$BUILD_DIR/DEBIAN/prerm"

# Build Debian package
echo "Building Debian package..."
DEB_FILE="${PACKAGE_NAME}_${PACKAGE_VERSION}_all.deb"
dpkg-deb --build "$BUILD_DIR" "$DEB_FILE"

if [ -f "$DEB_FILE" ]; then
    echo ""
    echo "Debian package built successfully: $DEB_FILE"
    echo ""
    echo "To install the package:"
    echo "  sudo dpkg -i $DEB_FILE"
    echo "  sudo apt-get install -f"
    echo ""
    echo "To remove the package:"
    echo "  sudo dpkg -r $PACKAGE_NAME"
else
    echo ""
    echo "Error: Debian package build failed"
    exit 1
fi

echo ""
echo "====================================================="
echo "  Build Complete"
echo "====================================================="
echo ""

exit 0
