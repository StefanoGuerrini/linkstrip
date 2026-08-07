.PHONY: all build release app app-universal test clean run

APP_NAME := LinkStrip
BUNDLE_ID := com.linkstrip.app
BUILD_DIR := .build
RELEASE_DIR := $(BUILD_DIR)/release
APP_BUNDLE := $(BUILD_DIR)/$(APP_NAME).app
EXECUTABLE := $(RELEASE_DIR)/$(APP_NAME)
SHARE_EXT_NAME := LinkStripShareExtension
SHARE_EXT_BUNDLE := $(BUILD_DIR)/$(SHARE_EXT_NAME).appex
SHARE_EXT_EXEC := $(BUILD_DIR)/$(SHARE_EXT_NAME)

# Build for the current machine architecture by default.
ARCH := $(shell uname -m)
TARGET := $(ARCH)-apple-macosx13.0

all: app

build:
	swift build

release:
	swift build -c release

release-universal:
	@echo "Building universal release binary (requires Xcode) ..."
	@swift build -c release --arch arm64 --arch x86_64

icons:
	@source .venv/bin/activate && python3 scripts/generate-icon.py
	@iconutil -c icns assets/AppIcon.iconset -o assets/AppIcon.icns

share-extension:
	@echo "Building $(SHARE_EXT_NAME).appex ..."
	@mkdir -p $(BUILD_DIR)
	@swiftc -O -target $(TARGET) \
		-module-name $(SHARE_EXT_NAME) \
		-framework Cocoa \
		-framework Foundation \
		-framework UserNotifications \
		-o $(SHARE_EXT_EXEC) \
		Sources/LinkStripShareExtension/main.swift \
		Sources/LinkStripShareExtension/ShareViewController.swift \
		Sources/LinkStrip/URLCleaner.swift
	@rm -rf $(SHARE_EXT_BUNDLE)
	@mkdir -p $(SHARE_EXT_BUNDLE)/Contents/MacOS
	@mkdir -p $(SHARE_EXT_BUNDLE)/Contents/Resources
	@cp $(SHARE_EXT_EXEC) $(SHARE_EXT_BUNDLE)/Contents/MacOS/$(SHARE_EXT_NAME)
	@cp ShareExtension/Info.plist $(SHARE_EXT_BUNDLE)/Contents/Info.plist
	@cp Sources/LinkStrip/Resources/tracking-params.json $(SHARE_EXT_BUNDLE)/Contents/Resources/tracking-params.json
	@codesign --sign - --force --entitlements ShareExtension/ShareExtension.entitlements $(SHARE_EXT_BUNDLE)

app: release share-extension
	@echo "Packaging $(APP_NAME).app ..."
	@rm -rf $(APP_BUNDLE)
	@mkdir -p $(APP_BUNDLE)/Contents/MacOS
	@mkdir -p $(APP_BUNDLE)/Contents/Resources
	@mkdir -p $(APP_BUNDLE)/Contents/PlugIns
	@cp $(EXECUTABLE) $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
	@cp Info.plist $(APP_BUNDLE)/Contents/Info.plist
	@cp LinkStrip.entitlements $(APP_BUNDLE)/Contents/Resources/
	@cp Sources/LinkStrip/Resources/tracking-params.json $(APP_BUNDLE)/Contents/Resources/tracking-params.json
	@cp assets/AppIcon.icns $(APP_BUNDLE)/Contents/Resources/AppIcon.icns
	@cp assets/MenuBarIcon.png $(APP_BUNDLE)/Contents/Resources/MenuBarIcon.png
	@cp assets/MenuBarIcon@2x.png $(APP_BUNDLE)/Contents/Resources/MenuBarIcon@2x.png
	@cp Sources/LinkStrip/fonts/*.ttf $(APP_BUNDLE)/Contents/Resources/
	@cp -R $(SHARE_EXT_BUNDLE) $(APP_BUNDLE)/Contents/PlugIns/
	@codesign --sign - --force --deep --entitlements LinkStrip.entitlements $(APP_BUNDLE)
	@echo "Created $(APP_BUNDLE)"

app-universal: release-universal share-extension
	@echo "Packaging universal $(APP_NAME).app ..."
	@rm -rf $(APP_BUNDLE)
	@mkdir -p $(APP_BUNDLE)/Contents/MacOS
	@mkdir -p $(APP_BUNDLE)/Contents/Resources
	@mkdir -p $(APP_BUNDLE)/Contents/PlugIns
	@cp $(EXECUTABLE) $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
	@cp Info.plist $(APP_BUNDLE)/Contents/Info.plist
	@cp LinkStrip.entitlements $(APP_BUNDLE)/Contents/Resources/
	@cp Sources/LinkStrip/Resources/tracking-params.json $(APP_BUNDLE)/Contents/Resources/tracking-params.json
	@cp assets/AppIcon.icns $(APP_BUNDLE)/Contents/Resources/AppIcon.icns
	@cp assets/MenuBarIcon.png $(APP_BUNDLE)/Contents/Resources/MenuBarIcon.png
	@cp assets/MenuBarIcon@2x.png $(APP_BUNDLE)/Contents/Resources/MenuBarIcon@2x.png
	@cp Sources/LinkStrip/fonts/*.ttf $(APP_BUNDLE)/Contents/Resources/
	@cp -R $(SHARE_EXT_BUNDLE) $(APP_BUNDLE)/Contents/PlugIns/
	@codesign --sign - --force --deep --entitlements LinkStrip.entitlements $(APP_BUNDLE)
	@echo "Created universal $(APP_BUNDLE)"

app-with-icons: icons app
	@echo "Packaged $(APP_NAME).app with regenerated icons"

test:
	swift test

clean:
	rm -rf $(BUILD_DIR) $(APP_BUNDLE)

run: build
	.build/debug/$(APP_NAME)
