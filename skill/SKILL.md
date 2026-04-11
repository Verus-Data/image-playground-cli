---
name: image-playground
description: Generate images using Apple's Image Playground API from the command line. Use when the user wants to create AI-generated images, illustrations, animations, or sketches on a Mac with Apple Intelligence.
metadata:
  {
    "openclaw":
      {
        "emoji": "🎨",
        "os": ["darwin"],
        "requires": { "anyBins": ["swift"] },
        "primaryEnv": "IMAGE_PLAYGROUND_OUTPUT",
        "install":
          [
            {
              "id": "download-latest",
              "kind": "download",
              "label": "Download pre-built binary (recommended)",
              "url": "https://github.com/Verus-Data/image-playground-cli/releases/latest/download/image-playground-cli-latest.tar.gz",
              "archive": "tar.gz",
              "stripComponents": 1,
              "targetDir": "{baseDir}",
            },
          ],
      },
  }
---

# Image Playground Skill

Generate AI images using Apple's Image Playground API on macOS.

## Requirements

- macOS 15.4 or later
- Apple Silicon Mac (M1/M2/M3/M4)
- Apple Intelligence enabled

## Installation

The skill auto-installs the pre-built binary on first use. If you need to install manually:

```bash
# Download the latest release
curl -L https://github.com/Verus-Data/image-playground-cli/releases/latest/download/image-playground-cli-latest.tar.gz | tar xz --strip-components=1 -C ~/.openclaw/skills/image-playground/
```

Or build from source:
```bash
cd {baseDir}/app && make bundle
```

## Usage

```bash
{baseDir}/skill/scripts/image-playground.sh --prompt "A cat in a space suit" --style illustration --output ./output.png
```

## Parameters

- `--prompt` (required): Text description of the image to generate
- `--style` (optional): `illustration` (default), `animation`, or `sketch`
- `--output` (required): Path to save the generated PNG file
- `--jpeg-quality` (optional): Convert to JPEG with quality 1-100. Recommended: 85
- `--max-width` (optional): Resize to max width in pixels
- `--timeout` (optional): Seconds to wait for generation. Default: 120
- `--retries` (optional): Number of retries on failure. Default: 1
- `--check` (optional): Verify preconditions without generating an image

## Precondition Check

Before generating, verify your environment:

```bash
{baseDir}/skill/scripts/image-playground.sh --check
```

This checks:
- Mac is awake and unlocked
- Apple Silicon detected
- macOS 15.4+
- image-helper.app is present

## Sharing Images in Chat

Generate with JPEG conversion for chat compatibility:

```bash
{baseDir}/skill/scripts/image-playground.sh \
    --prompt "A serene Japanese garden" \
    --style illustration \
    --output ./output.png \
    --jpeg-quality 85 \
    --max-width 1024
```

Then share via message tool with the JPEG file (smaller, chat-friendly).