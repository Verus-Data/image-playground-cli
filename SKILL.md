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
- `--jpeg-quality` (optional): Convert to JPEG with specified quality (1-100). Recommended: 85
- `--max-width` (optional): Resize to maximum width while maintaining aspect ratio

## Important: Foreground Requirement

The Image Playground API requires the app to be in the foreground. The wrapper script handles this by:

1. Building the helper app (if not already built)
2. Launching it via `open` (which grants foreground status)
3. Waiting for the output file to appear
4. Reporting success or timeout

**This means a brief window will appear** while the image is generating (~15 seconds).

## Output

- Format: PNG (1536×1536 pixels, 2–4 MB)
- Typical file size: 2–4 MB

## Sharing Images in Chat

Generated images can be shared with users in chat. Here's the recommended approach:

### Option 1: JPEG Conversion (Recommended for WebChat)

Generate a web-optimized JPEG version that works well with chat interfaces:

```bash
./skill/scripts/image-playground.sh \
    --prompt "A cat in a space suit" \
    --style illustration \
    --output ./output.png \
    --jpeg-quality 85 \
    --max-width 1024
```

This creates:
- `./output.png` (original, 1536×1536)
- `./output.jpg` (web-optimized, ~100-300 KB)

**To share in chat:** Use the `message` tool with the JPEG file:

```json
{
  "action": "send",
  "channel": "webchat",
  "message": "Here's your generated image!",
  "media": "file:///path/to/output.jpg"
}
```

Or for channels that support file attachments:

```json
{
  "action": "sendAttachment",
  "channel": "bluebubbles",
  "target": "+15551234567",
  "path": "/path/to/output.jpg",
  "caption": "Generated image"
}
```

### Option 2: Display in Canvas (For Local Nodes)

If the user is on a Mac/iOS device with OpenClaw node running, display the image in canvas:

```bash
# Generate the image
./skill/scripts/image-playground.sh --prompt "A robot" --output ~/clawd/canvas/robot.png

# Then use canvas tool to present it
canvas action:present node:<node-id> target:file:///Users/me/clawd/canvas/robot.png
```

### Option 3: Use the Image Tool (For Analysis)

If you need the AI to analyze the generated image:

```json
{
  "image": "/path/to/output.jpg"
}
```

**Note:** The `image` tool has a size limit (~4MB). Always use the JPEG version or reduce dimensions if needed.

## Complete Workflow Example

1. Generate image with JPEG conversion:
   ```bash
   ./skill/scripts/image-playground.sh \
       --prompt "A serene Japanese garden with cherry blossoms" \
       --style illustration \
       --output ~/.openclaw/workspace/generated.png \
       --jpeg-quality 85 \
       --max-width 1024
   ```

2. Share with user via message tool:
   ```json
   {
     "action": "send",
     "message": "Here's your illustration of a Japanese garden!",
     "media": "file:///Users/me/.openclaw/workspace/generated.jpg"
   }
   ```

## Alternative: Always-On Mode

If you need to generate images frequently without the window flash, consider running an always-on app that listens for requests via XPC or HTTP. See the main README for details.
