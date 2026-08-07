.PHONY: all build release app test clean run

APP_NAME := LinkStrip
BUNDLE_ID := com.linkstrip.app
BUILD_DIR := .build
RELEASE_DIR := $(BUILD_DIR)/release
APP_BUNDLE := $(BUILD_DIR)/$(APP_NAME).app
EXECUTABLE := $(RELEASE_DIR)/$(APP_NAME)

all: app

build:
	swift build

release:
	swift build -c release

icons:
	@source .venv/bin/activate && python3 scripts/generate-icon.py
	@iconutil -c icns assets/AppIcon.iconset -o assets/AppIcon.icns

app: release icons
	@echo "Packaging $(APP_NAME).app ..."
	@rm -rf $(APP_BUNDLE)
	@mkdir -p $(APP_BUNDLE)/Contents/MacOS
	@mkdir -p $(APP_BUNDLE)/Contents/Resources
	@cp $(EXECUTABLE) $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
	@cp Info.plist $(APP_BUNDLE)/Contents/Info.plist
	@cp LinkStrip.entitlements $(APP_BUNDLE)/Contents/Resources/
	@cp Sources/LinkStrip/Resources/tracking-params.json $(APP_BUNDLE)/Contents/Resources/tracking-params.json
	@cp assets/AppIcon.icns $(APP_BUNDLE)/Contents/Resources/AppIcon.icns
	@codesign --sign - --force --deep --entitlements LinkStrip.entitlements $(APP_BUNDLE)
	@echo "Created $(APP_BUNDLE)"

test:
	swift test

clean:
	rm -rf $(BUILD_DIR) $(APP_BUNDLE)

run: build
	.build/debug/$(APP_NAME)
