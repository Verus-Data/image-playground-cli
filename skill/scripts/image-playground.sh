#!/bin/bash
# image-playground.sh — OpenClaw skill wrapper for Image Playground CLI
#
# Usage: image-playground.sh --prompt "text" --style illustration --output /path/to/save.png [--jpeg-quality 85] [--max-width 1024]
#
# This wrapper:
# 1. Builds the helper app if needed
# 2. Launches it via `open` (required for foreground status)
# 3. Waits for the output file to appear
# 4. Optionally converts to JPEG for smaller file size (webchat compatible)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/../../app" && pwd)"
APP_BUNDLE="$APP_DIR/image-helper.app"

# Parse arguments
PROMPT=""
STYLE="illustration"
OUTPUT=""
JPEG_QUALITY=""
MAX_WIDTH=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --prompt)
            PROMPT="$2"
            shift 2
            ;;
        --style)
            STYLE="$2"
            shift 2
            ;;
        --output)
            OUTPUT="$2"
            shift 2
            ;;
        --jpeg-quality)
            JPEG_QUALITY="$2"
            shift 2
            ;;
        --max-width)
            MAX_WIDTH="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1" >&2
            echo "Usage: $0 --prompt \"text\" --style illustration|animation|sketch --output /path/to/save.png [--jpeg-quality 85] [--max-width 1024]" >&2
            exit 1
            ;;
    esac
done

if [[ -z "$PROMPT" || -z "$OUTPUT" ]]; then
    echo "Usage: $0 --prompt \"text\" --style illustration|animation|sketch --output /path/to/save.png [--jpeg-quality 85] [--max-width 1024]" >&2
    exit 1
fi

# Build the app bundle if needed
if [[ ! -d "$APP_BUNDLE" ]]; then
    echo "Building image-helper app..."
    cd "$APP_DIR"
    make bundle
fi

# Prepare output directory
OUTPUT_DIR="$(dirname "$OUTPUT")"
mkdir -p "$OUTPUT_DIR"

# Remove any pre-existing output file to avoid false positives
rm -f "$OUTPUT"

# Launch the app with environment variables
IMAGE_HELPER_PROMPT="$PROMPT" \
IMAGE_HELPER_STYLE="$STYLE" \
IMAGE_HELPER_OUTPUT="$OUTPUT" \
open "$APP_BUNDLE"

# Wait for the output file to appear (up to 120 seconds)
TIMEOUT=120
ELAPSED=0
INTERVAL=1

while [[ ! -f "$OUTPUT" ]]; do
    sleep "$INTERVAL"
    ELAPSED=$((ELAPSED + INTERVAL))
    if [[ $ELAPSED -ge $TIMEOUT ]]; then
        echo "Error: Timed out waiting for image generation ($TIMEOUT seconds)" >&2
        exit 2
    fi
done

echo "Image generated successfully: $OUTPUT"

# If JPEG conversion is requested, create a web-optimized version
if [[ -n "$JPEG_QUALITY" ]]; then
    # Determine output paths
    OUTPUT_DIR="$(dirname "$OUTPUT")"
    OUTPUT_BASE="$(basename "$OUTPUT" .png)"
    JPEG_OUTPUT="$OUTPUT_DIR/${OUTPUT_BASE}.jpg"
    
    # Build convert command
    CONVERT_CMD=(convert "$OUTPUT")
    
    # Add resize if max-width specified
    if [[ -n "$MAX_WIDTH" ]]; then
        CONVERT_CMD+=(-resize "${MAX_WIDTH}x${MAX_WIDTH}>")
    fi
    
    # Add JPEG quality and output
    CONVERT_CMD+=(-quality "$JPEG_QUALITY" "$JPEG_OUTPUT")
    
    # Try ImageMagick convert first, fallback to sips (macOS built-in)
    if command -v convert &> /dev/null; then
        "${CONVERT_CMD[@]}"
        echo "Web-optimized JPEG created: $JPEG_OUTPUT"
    elif command -v sips &> /dev/null; then
        # sips doesn't have quality parameter, but can resize and convert
        if [[ -n "$MAX_WIDTH" ]]; then
            sips -Z "$MAX_WIDTH" -s format jpeg "$OUTPUT" --out "$JPEG_OUTPUT" &> /dev/null
        else
            sips -s format jpeg "$OUTPUT" --out "$JPEG_OUTPUT" &> /dev/null
        fi
        echo "Web-optimized JPEG created: $JPEG_OUTPUT"
    else
        echo "Warning: No image conversion tool found. Install ImageMagick for JPEG conversion." >&2
    fi
fi
