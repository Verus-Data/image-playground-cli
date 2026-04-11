#!/bin/bash
# image-playground.sh — OpenClaw skill wrapper for Image Playground CLI
#
# Usage: image-playground.sh --prompt "text" --style illustration --output /path/to/save.png [--jpeg-quality 85] [--max-width 1024] [--timeout 120] [--retries 1]
#        image-playground.sh --check  (verify preconditions without generating)
#
# This wrapper:
# 1. Checks preconditions (Mac awake, Apple Intelligence available)
# 2. Kills any stale image-helper processes
# 3. Launches the app and forces foreground
# 4. Retries once on failure (handles intermittent foreground issues)
# 5. Waits for output with progress indicator
# 6. Optionally converts to JPEG

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DIST_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_BUNDLE="$DIST_DIR/image-helper.app"
APP_NAME="image-helper"

# Configuration
MAX_RETRIES=1
RETRY_DELAY=5

error_exit() {
    local code=$1
    local msg=$2
    local recovery="${3:-}"
    echo "" >&2
    echo "Error: $msg" >&2
    if [[ -n "$recovery" ]]; then
        echo "" >&2
        echo "Recovery:" >&2
        echo "  $recovery" >&2
    fi
    exit "$code"
}

check_preconditions() {
    local failures=0

    echo "Checking preconditions..."

    # Check if Mac is awake and unlocked
    if ! is_mac_awake_and_unlocked; then
        echo "  ✗ Mac is locked, asleep, or screen saver is active" >&2
        failures=$((failures + 1))
    else
        echo "  ✓ Mac is awake and unlocked"
    fi

    # Check Apple Silicon
    local arch=$(uname -m)
    if [[ "$arch" != "arm64" ]]; then
        echo "  ✗ Not Apple Silicon ($arch) — Image Playground requires M1/M2/M3/M4" >&2
        failures=$((failures + 1))
    else
        echo "  ✓ Apple Silicon detected"
    fi

    # Check macOS version (need 15.4+)
    local os_version=$(sw_vers -productVersion)
    local major=$(echo "$os_version" | cut -d. -f1)
    local minor=$(echo "$os_version" | cut -d. -f2)
    if [[ "$major" -lt 15 ]] || [[ "$major" -eq 15 && "$minor" -lt 4 ]]; then
        echo "  ✗ macOS $os_version — requires 15.4+" >&2
        failures=$((failures + 1))
    else
        echo "  ✓ macOS $os_version"
    fi

    # Check for app bundle
    if [[ ! -d "$APP_BUNDLE" ]]; then
        echo "  ✗ image-helper.app not found at $APP_BUNDLE" >&2
        failures=$((failures + 1))
    else
        echo "  ✓ image-helper.app found"
    fi

    if [[ $failures -gt 0 ]]; then
        echo "" >&2
        echo "$failures precondition(s) failed." >&2
        return 1
    fi

    return 0
}

is_mac_awake_and_unlocked() {
    # Check if screen is locked using ScreenSaver state
    local saver_state=$(osascript -e 'tell application "System Events" to return name of current screen saver' 2>/dev/null || echo "none")
    if [[ "$saver_state" != "none" && -n "$saver_state" ]]; then
        return 1
    fi

    # Check if display is asleep using pmset
    local displaysleep=$(pmset -g powerstate IODisplayWrangler 2>/dev/null | grep "Current" | awk '{print $3}' || echo "")
    if [[ "$displaysleep" == "OFF" ]]; then
        return 1
    fi

    return 0
}

kill_stale_processes() {
    # Find and kill any existing image-helper processes
    local pids=$(pgrep -f "image-helper" || true)
    if [[ -n "$pids" ]]; then
        echo "Cleaning up stale image-helper process(es): $pids"
        kill $pids 2>/dev/null || true
        sleep 1
        # Force kill if still running
        kill -9 $pids 2>/dev/null || true
        sleep 0.5
    fi
}

force_foreground() {
    # Activate the app via AppleScript
    osascript -e "tell application \"$APP_NAME\" to activate" 2>/dev/null || true

    # Also try direct binary execution as fallback (runs in background)
    if [[ -x "$APP_BUNDLE/Contents/MacOS/$APP_NAME" ]]; then
        local helper_pid
        "$APP_BUNDLE/Contents/MacOS/$APP_NAME" &
        helper_pid=$!
        echo $helper_pid
        return 0
    fi

    return 1
}

wait_for_generation() {
    local output="$1"
    local timeout="${2:-120}"
    local start_time=$(date +%s)

    echo -n "Waiting for generation "

    while [[ ! -f "$output" ]]; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))

        if [[ $elapsed -ge $timeout ]]; then
            echo ""
            echo ""
            return 1
        fi

        # Show progress every 5 seconds
        if [[ $((elapsed % 5)) -eq 0 && $elapsed -gt 0 ]]; then
            echo -n "."
        fi

        sleep 1
    done

    echo ""
    return 0
}

generate_image() {
    local prompt="$1"
    local style="$2"
    local output="$3"
    local timeout="$4"

    # Clean up any existing output
    rm -f "$output"

    # Kill stale processes before launching
    kill_stale_processes

    # Launch with environment variables
    IMAGE_HELPER_PROMPT="$prompt" \
    IMAGE_HELPER_STYLE="$style" \
    IMAGE_HELPER_OUTPUT="$output" \
    open "$APP_BUNDLE"

    # Try to force foreground
    sleep 1
    local direct_pid=$(force_foreground)

    # Wait for output
    if wait_for_generation "$output" "$timeout"; then
        return 0
    else
        return 1
    fi
}

# Parse arguments
PROMPT=""
STYLE="illustration"
OUTPUT=""
JPEG_QUALITY=""
MAX_WIDTH=""
TIMEOUT=120
CHECK_ONLY=false
RETRIES=$MAX_RETRIES

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
        --retries)
            RETRIES="$2"
            shift 2
            ;;
        --check)
            CHECK_ONLY=true
            shift
            ;;
        *)
            echo "Unknown argument: $1" >&2
            echo "" >&2
            echo "Usage: $0 --prompt \"text\" --style illustration|animation|sketch --output /path/to/save.png [options]" >&2
            echo "" >&2
            echo "Options:" >&2
            echo "  --jpeg-quality N   Convert to JPEG with quality N (1-100)" >&2
            echo "  --max-width N      Resize to max width N pixels" >&2
            echo "  --timeout N        Wait up to N seconds (default: 120)" >&2
            echo "  --retries N        Retry N times on failure (default: 1)" >&2
            echo "  --check            Verify preconditions without generating" >&2
            exit 1
            ;;
    esac
done

# --check mode
if [[ "$CHECK_ONLY" == true ]]; then
    check_preconditions
    exit $?
fi

# Validate required args
if [[ -z "$PROMPT" || -z "$OUTPUT" ]]; then
    echo "Usage: $0 --prompt \"text\" --style illustration|animation|sketch --output /path/to/save.png [options]" >&2
    exit 1
fi

# Check preconditions
if ! check_preconditions; then
    error_exit 4 "Precondition check failed." \
        "Unlock your Mac, ensure the screen is active, and verify Apple Intelligence is enabled in System Settings."
fi

# Create output directory
OUTPUT_DIR="$(dirname "$OUTPUT")"
mkdir -p "$OUTPUT_DIR"

# Main generation loop with retries
attempt=0
while [[ $attempt -le $RETRIES ]]; do
    if [[ $attempt -gt 0 ]]; then
        echo ""
        echo "Retry attempt $attempt/$RETRIES in ${RETRY_DELAY}s..."
        sleep $RETRY_DELAY
    fi

    if generate_image "$PROMPT" "$STYLE" "$OUTPUT" "$TIMEOUT"; then
        break
    fi

    attempt=$((attempt + 1))
done

if [[ ! -f "$OUTPUT" ]]; then
    error_exit 2 "Image generation failed after $((attempt)) attempt(s)." \
        "The Image Playground framework requires a fresh foreground session. Try:\n  1. Ensure no other image-helper processes are running (killall image-helper)\n  2. Run 'open -a image-helper' manually once to warm up the framework\n  3. Retry the command"
fi

echo ""
echo "✓ Image generated successfully: $OUTPUT"

# Optional JPEG conversion
if [[ -n "$JPEG_QUALITY" ]]; then
    JPEG_OUTPUT="${OUTPUT%.png}.jpg"

    if command -v convert &> /dev/null; then
        convert "$OUTPUT" -quality "$JPEG_QUALITY" ${MAX_WIDTH:+-resize "${MAX_WIDTH}x${MAX_WIDTH}>"} "$JPEG_OUTPUT"
        echo "✓ JPEG created: $JPEG_OUTPUT"
    elif command -v sips &> /dev/null; then
        if [[ -n "$MAX_WIDTH" ]]; then
            sips -Z "$MAX_WIDTH" -s format jpeg "$OUTPUT" --out "$JPEG_OUTPUT" &> /dev/null
        else
            sips -s format jpeg "$OUTPUT" --out "$JPEG_OUTPUT" &> /dev/null
        fi
        echo "✓ JPEG created: $JPEG_OUTPUT"
    else
        echo "⚠ Warning: No image conversion tool found (ImageMagick or sips)" >&2
    fi
fi