#!/bin/bash
# image-playground.sh — OpenClaw skill wrapper for Image Playground CLI
#
# Usage: image-playground.sh --prompt "text" --style illustration --output /path/to/save.png [--jpeg-quality 85] [--max-width 1024] [--timeout 120]
#        image-playground.sh --check  (verify preconditions without generating)
#
# This wrapper:
# 1. Checks preconditions (Mac awake, Apple Intelligence available)
# 2. Builds the helper app if needed
# 3. Launches it via `open` (required for foreground status)
# 4. Forces foreground aggressively with osascript
# 5. Waits for the output file to appear
# 6. Optionally converts to JPEG for smaller file size (webchat compatible)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DIST_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_BUNDLE="$DIST_DIR/image-helper.app"
APP_NAME="image-helper"

check_preconditions() {
    local failures=0

    echo "Checking preconditions..."

    if ! is_mac_awake; then
        echo "FAIL: Mac appears to be locked or asleep." >&2
        echo "  -> Unlock your Mac and ensure the screen is active." >&2
        failures=$((failures + 1))
    else
        echo "OK: Mac is awake and unlocked."
    fi

    if ! check_apple_intelligence; then
        echo "FAIL: Apple Intelligence / Image Playground not available." >&2
        echo "  -> Requires macOS 15.4+ and Apple Silicon (M1+)." >&2
        failures=$((failures + 1))
    else
        echo "OK: Apple Intelligence appears available."
    fi

    if [[ ! -d "$APP_BUNDLE" ]]; then
        echo "FAIL: image-helper.app not found at $APP_BUNDLE" >&2
        failures=$((failures + 1))
    else
        echo "OK: image-helper.app bundle found."
    fi

    return $failures
}

is_mac_awake() {
    python3 -c "
import subprocess
try:
    result = subprocess.run(['osascript', '-e', '''
tell application \"System Events\"
    set screenState to (do shell script \"pmset get displaysleep\" as string)
    return screenState
end tell
'''], capture_output=True, text=True, timeout=5)
    output = result.stdout.strip().lower()
    if 'never' in output or '0' in output:
        print('awake')
    else:
        print('sleeping')
except Exception:
    try:
        import Quartz
        session = Quartz.CGSessionCopyCurrentDictionary()
        if session:
            print('awake')
        else:
            print('sleeping')
    except Exception:
        print('unknown')
" 2>/dev/null | grep -q "awake"
}

check_apple_intelligence() {
    local os_version kernel_arch
    os_version=$(sw_vers -productVersion)
    kernel_arch=$(uname -m)

    if [[ "$kernel_arch" != "arm64" ]]; then
        return 1
    fi

    local major minor
    major=$(echo "$os_version" | cut -d. -f1)
    minor=$(echo "$os_version" | cut -d. -f2)

    if [[ "$major" -lt 15 ]] || [[ "$major" -eq 15 && "$minor" -lt 4 ]]; then
        return 1
    fi

    return 0
}

force_foreground() {
    sleep 1
    osascript -e "tell application \"$APP_NAME\" to activate" 2>/dev/null || true
    sleep 0.5
    if [[ -x "$APP_BUNDLE/Contents/MacOS/$APP_NAME" ]]; then
        "$APP_BUNDLE/Contents/MacOS/$APP_NAME" &
    fi
    sleep 0.5
}

print_spinner() {
    local pid=$1
    local delay=0.2
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        local temp=${spinstr:i%${#spinstr}:1}
        printf "\r[%c] Waiting for image... " "$temp"
        sleep $delay
        i=$(( (i + 1) % ${#spinstr} ))
    done
    printf "\r%-50s\r" ""
}

wait_for_output() {
    local output=$1
    local timeout=${2:-120}
    local elapsed=0
    local interval=1

    while [[ ! -f "$OUTPUT" ]]; do
        sleep "$interval"
        elapsed=$((elapsed + interval))

        if ! kill -0 $$ 2>/dev/null; then
            echo "Error: Script interrupted" >&2
            return 1
        fi

        if [[ $elapsed -ge $timeout ]]; then
            echo "" >&2
            echo "Error: Timed out waiting for image generation ($timeout seconds)" >&2
            echo "This typically happens when:" >&2
            echo "  - The Mac is locked or asleep" >&2
            echo "  - The app cannot get foreground focus" >&2
            echo "  - Apple Intelligence is unavailable" >&2
            return 1
        fi

        printf "."
    done

    return 0
}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DIST_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_BUNDLE="$DIST_DIR/image-helper.app"

PROMPT=""
STYLE="illustration"
OUTPUT=""
JPEG_QUALITY=""
MAX_WIDTH=""
TIMEOUT=120
CHECK_ONLY=false

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
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        --check)
            CHECK_ONLY=true
            shift
            ;;
        *)
            echo "Unknown argument: $1" >&2
            echo "Usage: $0 --prompt \"text\" --style illustration|animation|sketch --output /path/to/save.png [--jpeg-quality 85] [--max-width 1024] [--timeout 120]" >&2
            echo "       $0 --check" >&2
            exit 1
            ;;
    esac
done

if [[ "$CHECK_ONLY" == true ]]; then
    check_preconditions
    exit $?
fi

if [[ -z "$PROMPT" || -z "$OUTPUT" ]]; then
    echo "Usage: $0 --prompt \"text\" --style illustration|animation|sketch --output /path/to/save.png [--jpeg-quality 85] [--max-width 1024] [--timeout 120]" >&2
    echo "       $0 --check" >&2
    exit 1
fi

if ! check_preconditions; then
    echo "" >&2
    echo "Precondition check failed. Fix the issues above before retrying." >&2
    exit 4
fi

if [[ ! -d "$APP_BUNDLE" ]]; then
    echo "Error: image-helper.app not found at $APP_BUNDLE" >&2
    echo "The app bundle must be included with the skill distribution." >&2
    exit 3
fi

OUTPUT_DIR="$(dirname "$OUTPUT")"
mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT"

IMAGE_HELPER_PROMPT="$PROMPT" \
IMAGE_HELPER_STYLE="$STYLE" \
IMAGE_HELPER_OUTPUT="$OUTPUT" \
open "$APP_BUNDLE"

force_foreground

if ! wait_for_output "$OUTPUT" "$TIMEOUT"; then
    exit 2
fi

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
