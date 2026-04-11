---
name: image-playground
description: Generate images using Apple's Image Playground API from the command line. Use when the user wants to create AI-generated images, illustrations, animations, or sketches on a Mac with Apple Intelligence.
---

# Image Playground Skill

This skill provides command-line access to Apple's Image Playground API for generating AI images.

## Requirements

- macOS 15.4 or later
- Apple Silicon Mac (M1/M2/M3/M4)
- Apple Intelligence enabled
- The `image-helper` app must be built

## Usage

The skill wrapper script handles building the app if needed and calling it with the right arguments:

```bash
./skill/scripts/image-playground.sh --prompt "A cat in a space suit" --style illustration --output ./output.png
```

## Parameters

- `--prompt` (required): Text description of the image to generate
- `--style` (optional): One of `illustration`, `animation`, or `sketch`. Defaults to `illustration`
- `--output` (required): Path to save the generated PNG file

## Important: Foreground Requirement

The Image Playground API requires the app to be in the foreground. The wrapper script handles this by:

1. Building the helper app (if not already built)
2. Launching it via `open` (which grants foreground status)
3. Waiting for the output file to appear
4. Reporting success or timeout

**This means a brief window will appear** while the image is generating (~15 seconds).

## Alternative: Always-On Mode

If you need to generate images frequently without the window flash, consider running an always-on app that listens for requests via XPC or HTTP. See the main README for details.

## Output

- Format: PNG
- Resolution: 1536×1536 pixels
- Typical file size: 2–4 MB
