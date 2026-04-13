#!/bin/bash
# build.sh — Build script for image-playground-cli
#
# This script builds the Swift helper app and prepares the CLI for distribution.
# It creates a distributable package with the binary and all necessary files.

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$SCRIPT_DIR/app"
BUILD_DIR="$SCRIPT_DIR/dist"
VERSION="1.0.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check macOS version
    if ! sw_vers -productVersion &>/dev/null; then
        log_error "This tool requires macOS 15.4 or later"
        exit 1
    fi
    
    # Check Swift
    if ! command -v swift &>/dev/null; then
        log_error "Swift is not installed. Please install Xcode 16 or later."
        exit 1
    fi
    
    # Check for Apple Silicon
    if [[ "$(uname -m)" != "arm64" ]]; then
        log_error "This tool requires Apple Silicon (M1/M2/M3/M4). Intel Macs are not supported."
        exit 1
    fi
    
    log_info "Prerequisites check passed ✓"
}

# Clean previous builds
clean_build() {
    log_info "Cleaning previous builds..."
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
    cd "$APP_DIR"
    make clean 2>/dev/null || true
}

# Build the Swift app
build_app() {
    log_info "Building image-helper app..."
    cd "$APP_DIR"
    
    # Build and bundle
    make bundle
    
    if [[ ! -d "$APP_DIR/image-helper.app" ]]; then
        log_error "Build failed: image-helper.app not found"
        exit 1
    fi
    
    log_info "Build successful ✓"
}

# Copy files to dist directory
package_dist() {
    log_info "Packaging distribution..."
    
    # Create directory structure
    mkdir -p "$BUILD_DIR/image-playground-cli"
    
    # Copy the app bundle
    cp -R "$APP_DIR/image-helper.app" "$BUILD_DIR/image-playground-cli/"
    
    # Copy the skill wrapper script
    mkdir -p "$BUILD_DIR/image-playground-cli/skill/scripts"
    cp "$SCRIPT_DIR/skill/scripts/image-playground.sh" "$BUILD_DIR/image-playground-cli/skill/scripts/"
    chmod +x "$BUILD_DIR/image-playground-cli/skill/scripts/image-playground.sh"
    
    # Copy documentation
    cp "$SCRIPT_DIR/docs/README.md" "$BUILD_DIR/image-playground-cli/"
    cp "$SCRIPT_DIR/LICENSE" "$BUILD_DIR/image-playground-cli/"
    
    # Copy SKILL.md to both root and skill/ for compatibility
    cp "$SCRIPT_DIR/skill/SKILL.md" "$BUILD_DIR/image-playground-cli/"
    cp "$SCRIPT_DIR/skill/SKILL.md" "$BUILD_DIR/image-playground-cli/skill/"
    
    log_info "Package created at: $BUILD_DIR/image-playground-cli/"
}

# Create a tarball for release
create_release_tarball() {
    log_info "Creating release tarball..."
    cd "$BUILD_DIR"
    
    # Create tarball
    tar -czf "image-playground-cli-${VERSION}.tar.gz" image-playground-cli/
    
    # Create checksum
    shasum -a 256 "image-playground-cli-${VERSION}.tar.gz" > "image-playground-cli-${VERSION}.sha256"
    
    log_info "Release tarball created: $BUILD_DIR/image-playground-cli-${VERSION}.tar.gz"
    log_info "Checksum: $(cat "$BUILD_DIR/image-playground-cli-${VERSION}.sha256")"
}

# Print summary
print_summary() {
    echo ""
    echo "========================================"
    echo "Build Complete!"
    echo "========================================"
    echo ""
    echo "Distribution files:"
    echo "  - $BUILD_DIR/image-playground-cli/ (folder)"
    echo "  - $BUILD_DIR/image-playground-cli-${VERSION}.tar.gz (tarball)"
    echo "  - $BUILD_DIR/image-playground-cli-${VERSION}.sha256 (checksum)"
    echo ""
    echo "To use locally:"
    echo "  ./skill/scripts/image-playground.sh --prompt 'A cat in space' --output ./test.png"
    echo ""
    echo "To create a GitHub release:"
    echo "  1. Tag the release: git tag -a v${VERSION} -m 'Release v${VERSION}'"
    echo "  2. Push the tag: git push origin v${VERSION}"
    echo "  3. Attach the tarball to the release"
    echo ""
}

# Main execution
main() {
    echo "========================================"
    echo "Building image-playground-cli v${VERSION}"
    echo "========================================"
    echo ""
    
    check_prerequisites
    clean_build
    build_app
    package_dist
    create_release_tarball
    print_summary
}

main "$@"
