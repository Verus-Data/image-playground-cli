# Image Playground CLI

A command-line interface for generating images using Apple's Image Playground API on macOS.

## What It Does

This tool allows you to generate AI images from text prompts using Apple's on-device Image Playground framework. It's useful for:

- Creating illustrations, animations, and sketches from text descriptions
- Batch image generation via scripts
- Integration with other CLI workflows
- Automation pipelines that need image generation

## Requirements

- **macOS 15.4 or later**
- **Apple Silicon Mac** (M1/M2/M3/M4 series)
- **Apple Intelligence enabled** in System Settings

The Image Playground framework is only available on Apple Silicon Macs with Apple Intelligence support. It will not work on Intel Macs or older macOS versions.

## How to Build

The project includes a SwiftUI helper app that must be built first:

```bash
cd app
make
```

Or manually:

```bash
cd app
swift build
make bundle  # Creates image-helper.app
```

## How to Use the Wrapper Script

The recommended way to use this tool is via the wrapper script:

```bash
./skill/scripts/image-playground.sh \
    --prompt "A cat in a space suit floating in zero gravity" \
    --style illustration \
    --output ./space-cat.png
```

### Available Styles

- `illustration` (default) — Colorful illustrated style
- `animation` — Animation/cartoon style  
- `sketch` — Pencil sketch style

### Examples

```bash
# Generate an illustration
./skill/scripts/image-playground.sh \
    --prompt "A serene Japanese garden with cherry blossoms" \
    --output ./garden.png

# Generate an animation-style image
./skill/scripts/image-playground.sh \
    --prompt "A robot learning to paint" \
    --style animation \
    --output ./robot-artist.png

# Generate a sketch
./skill/scripts/image-playground.sh \
    --prompt "An old Victorian house on a hill" \
    --style sketch \
    --output ./haunted-house.png
```

## The Foreground Limitation (Important!)

Apple's Image Playground API requires the generating app to be in the foreground. If called from a background process, it fails with `backgroundCreationForbidden`.

### How This Tool Works Around It

The wrapper script:
1. Builds the helper app as a proper `.app` bundle
2. Launches it via macOS `open` command (grants foreground status)
3. Shows a brief "Generating image..." window (~15 seconds)
4. Auto-exits after saving the image

### The Window Flash

When you run the wrapper script, you'll see a small window appear while the image generates. This is unavoidable — it's what grants the app foreground status. The window auto-closes when complete.

### Workarounds for Frequent Use

If you're generating images frequently and the window flash is disruptive:

**Option 1: Always-On App**
Run a persistent app (in the menu bar or dock) that listens for image generation requests via XPC, HTTP, or file watcher. This eliminates the startup delay and window flash.

**Option 2: Shortcut/Automation**
Create a macOS Shortcut that calls the wrapper script — the window will still appear but Shortcuts can be triggered via voice or keyboard.

**Option 3: Background Service**
Modify the app to stay running and accept multiple generation requests before exiting.

## Output Specifications

- **Format:** PNG
- **Resolution:** 1536×1536 pixels
- **File size:** Typically 2–4 MB
- **Generation time:** ~15 seconds per image

## Sharing in Chat

To share generated images in OpenClaw webchat or other channels, use the JPEG conversion options:

```bash
./skill/scripts/image-playground.sh \
    --prompt "A cat in a space suit" \
    --style illustration \
    --output ./output.png \
    --jpeg-quality 85 \
    --max-width 1024
```

This creates a web-optimized JPEG (~100-300 KB) alongside the original PNG. The JPEG can be shared using the `message` tool with the `media` parameter. See the skill documentation for complete details.

## Project Structure

```
image-playground-cli/
├── app/                          # SwiftUI helper app
│   ├── Package.swift            # Swift package manifest
│   ├── Sources/
│   │   └── main.swift           # SwiftUI app with ImageCreator
│   └── Makefile                 # Build automation
├── skill/                        # OpenClaw skill definition
│   ├── SKILL.md                 # Skill documentation
│   └── scripts/
│       └── image-playground.sh  # Wrapper script
└── README.md                     # This file
```

## Troubleshooting

### "backgroundCreationForbidden" error

This means the app isn't in the foreground. Make sure you're using the wrapper script, not calling the binary directly.

### Build errors

Ensure you're on macOS 15.4+ with Xcode 16 or later:

```bash
swift --version
sw_vers
```

### No image generated (timeout)

- Check that Apple Intelligence is enabled in System Settings → Apple Intelligence
- Ensure your Mac supports Apple Intelligence (M1 or later)
- Try a simpler prompt — some content may be filtered

## License

MIT License — See LICENSE file for details.

## Credits

Created for the OpenClaw ecosystem. Uses Apple's ImagePlayground framework.
