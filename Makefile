FLUTTER?=$(realpath $(dir $(realpath $(dir $(shell which flutter)))))
FLUTTER_BIN=$(FLUTTER)/bin/flutter
DART_BIN=$(FLUTTER)/bin/dart
DART_SRC=$(shell find . -name '*.dart')
VERSION=$(shell grep -E '^version:' pubspec.yaml | sed 's/version: */v/g')
SERVER_PATH=jmaybee@50.116.95.106:public_html/demo/
FASTLANE=$(shell which fastlane || echo "bundle exec fastlane")

all: build-dep format

build-dep: .packages

format: format-dart

format-dart: $(DART_SRC)
	$(DART_BIN) format --fix $^

.packages: pubspec.yaml pubspec.lock
	rm -f ios/Flutter/Generated.xcconfig android/local.properties
	$(FLUTTER_BIN) pub get

clean:
	git clean -fdx -e .vscode

fix:
	$(DART_BIN) fix --apply

analyze: build-dep format
	$(DART_BIN) analyze --fatal-infos

test: build-dep
	$(FLUTTER_BIN) test --coverage --coverage-path lcov.info

.PHONY: format format-dart clean test fix analyze android web publish-web

deploy:
	git tag '$(VERSION)'
	git push --tags

# Android

android: app-release-$(VERSION).apk

app-release-$(VERSION).apk: build-dep $(DART_SRC)
	flutter build apk --suppress-analytics -v --release --split-debug-info=build/app/outputs/debug-info --obfuscate
	cp build/app/outputs/apk/release/app-release.apk $@

# Web

build/web/main.dart.js: build-dep $(DART_SRC)
	flutter build web -v --release

web: build/web/main.dart.js

publish-web: build/web/main.dart.js build/web/index.html build/web/manifest.json
	rsync -a -v --progress --delete build/web/ $(SERVER_PATH)

# iOS
publish-ios: build-dep $(DART_SRC)
	cd ios && pod install
	cd ios; $(FASTLANE) beta

icons: build-dep
	flutter pub run flutter_launcher_icons:main

publish-android:
	cd android; bundle exec fastlane beta