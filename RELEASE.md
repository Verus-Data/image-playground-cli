# Release Guide

This document explains how to create a new release of image-playground-cli.

## Automated Release (Recommended)

The easiest way to create a release is using GitHub Actions:

1. **Tag the release:**
   ```bash
   git tag -a v1.0.1 -m "Release v1.0.1"
   git push origin v1.0.1
   ```

2. **GitHub Actions will automatically:**
   - Build the app on macOS 15
   - Create a release tarball
   - Attach the binaries to a GitHub release
   - Generate checksums

## Manual Release

If you need to create a release manually:

### Prerequisites

- macOS 15.4 or later
- Apple Silicon Mac (M1/M2/M3/M4)
- Xcode 16 or later with Swift 6.0
- Git

### Build Process

1. **Clone the repository:**
   ```bash
   git clone <repo-url>
   cd image-playground-cli
   ```

2. **Run the build script:**
   ```bash
   ./build.sh
   ```

3. **The build script will:**
   - Check prerequisites (macOS version, Swift, Apple Silicon)
   - Build the Swift helper app
   - Create a distribution in `dist/image-playground-cli/`
   - Package it as `dist/image-playground-cli-VERSION.tar.gz`
   - Generate a SHA256 checksum

### Create GitHub Release

1. Go to your repository on GitHub
2. Click "Releases" → "Draft a new release"
3. Click "Choose a tag" and create a new tag (e.g., `v1.0.1`)
4. Set the release title (e.g., "Release v1.0.1")
5. Drag and drop the files from `dist/`:
   - `image-playground-cli-1.0.1.tar.gz`
   - `image-playground-cli-1.0.1.sha256`
6. Click "Publish release"

## Version Numbers

We follow [Semantic Versioning](https://semver.org/):

- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes

Update the version in `build.sh` before creating a new release:
```bash
VERSION="1.0.1"
```

## What Gets Released

Each release includes:

- `image-helper.app/` - The compiled Swift helper application
- `skill/scripts/image-playground.sh` - The wrapper script
- `README.md` - Documentation
- `LICENSE` - MIT License
- `skill/SKILL.md` - OpenClaw skill definition

## Verification

After downloading a release, verify the checksum:

```bash
shasum -a 256 -c image-playground-cli-1.0.1.sha256
```

Expected output:
```
image-playground-cli-1.0.1.tar.gz: OK
```
