# Makefile for image-helper
# Builds the Swift binary and packages it into a macOS app bundle

BINARY = .build/arm64-apple-macosx/debug/image-helper
BUNDLE = image-helper.app

.PHONY: all build bundle clean test

all: build bundle

build:
	swift build

bundle: build
	@mkdir -p $(BUNDLE)/Contents/MacOS
	@mkdir -p $(BUNDLE)/Contents/Resources
	cp $(BINARY) $(BUNDLE)/Contents/MacOS/
	@echo '<?xml version="1.0" encoding="UTF-8"?>' > $(BUNDLE)/Contents/Info.plist
	@echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> $(BUNDLE)/Contents/Info.plist
	@echo '<plist version="1.0">' >> $(BUNDLE)/Contents/Info.plist
	@echo '<dict>' >> $(BUNDLE)/Contents/Info.plist
	@echo '    <key>CFBundleExecutable</key>' >> $(BUNDLE)/Contents/Info.plist
	@echo '    <string>image-helper</string>' >> $(BUNDLE)/Contents/Info.plist
	@echo '    <key>CFBundleIdentifier</key>' >> $(BUNDLE)/Contents/Info.plist
	@echo '    <string>com.openclaw.image-helper</string>' >> $(BUNDLE)/Contents/Info.plist
	@echo '    <key>CFBundleName</key>' >> $(BUNDLE)/Contents/Info.plist
	@echo '    <string>Image Helper</string>' >> $(BUNDLE)/Contents/Info.plist
	@echo '    <key>CFBundleVersion</key>' >> $(BUNDLE)/Contents/Info.plist
	@echo '    <string>1.0</string>' >> $(BUNDLE)/Contents/Info.plist
	@echo '    <key>CFBundleShortVersionString</key>' >> $(BUNDLE)/Contents/Info.plist
	@echo '    <string>1.0</string>' >> $(BUNDLE)/Contents/Info.plist
	@echo '    <key>LSMinimumSystemVersion</key>' >> $(BUNDLE)/Contents/Info.plist
	@echo '    <string>15.4</string>' >> $(BUNDLE)/Contents/Info.plist
	@echo '    <key>LSUIElement</key>' >> $(BUNDLE)/Contents/Info.plist
	@echo '    <false/>' >> $(BUNDLE)/Contents/Info.plist
	@echo '    <key>NSHighResolutionCapable</key>' >> $(BUNDLE)/Contents/Info.plist
	@echo '    <true/>' >> $(BUNDLE)/Contents/Info.plist
	@echo '</dict>' >> $(BUNDLE)/Contents/Info.plist
	@echo '</plist>' >> $(BUNDLE)/Contents/Info.plist
	@echo "Bundle created: $(BUNDLE)"

test: bundle
	@echo "Testing illustration style..."
	@IMAGE_HELPER_PROMPT="A cat sitting on a windowsill" IMAGE_HELPER_STYLE=illustration IMAGE_HELPER_OUTPUT=/tmp/image-helper-test.png open $(BUNDLE)
	@sleep 15
	@if [ -f /tmp/image-helper-test.png ]; then echo "SUCCESS: Image generated"; sips -g pixelWidth -g pixelHeight /tmp/image-helper-test.png; rm /tmp/image-helper-test.png; else echo "FAILED: No image generated"; fi

clean:
	swift package clean
	rm -rf $(BUNDLE)
