# Install Tasks

install-iOS:
	true

install-OSX:
	true

install-tvOS:
	true

install-lint:
	brew remove swiftlint --force || true
	brew install https://raw.githubusercontent.com/Homebrew/homebrew-core/3d0cc175398ceba2c42204b04dd2a3b5d79536d9/Formula/swiftlint.rb

install-carthage:
	brew remove carthage --force || true
	brew install https://raw.githubusercontent.com/Homebrew/homebrew/b0ea85753ecee494dc97fc9f95c5afb9d0b447be/Library/Formula/carthage.rb

install-oss-osx:
	curl -sL https://gist.githubusercontent.com/kylef/5c0475ff02b7c7671d2a/raw/b07054552689910f79b3496221f7421a811f9f70/swiftenv-install.sh | bash

# Run Tasks

test-lint:
	swiftlint lint --strict 2>/dev/null

test-iOS:
	set -o pipefail && \
		xcodebuild \
		-project Kronos.xcodeproj \
		-scheme Kronos \
		-destination "name=iPhone 6s" \
		test \
		| xcpretty -ct

test-OSX:
	set -o pipefail && \
		xcodebuild \
		-project Kronos.xcodeproj \
		-scheme Kronos \
		test \
		| xcpretty -ct

test-tvOS:
	set -o pipefail && \
		xcodebuild \
		-project Kronos.xcodeproj \
		-scheme Kronos \
		-destination "name=Apple TV 1080p" \
		test \
		| xcpretty -ct

test-carthage:
	carthage build --no-skip-current
	ls Carthage/build/Mac/Kronos.framework
	ls Carthage/build/iOS/Kronos.framework
	ls Carthage/build/tvOS/Kronos.framework
	ls Carthage/build/watchOS/Kronos.framework

test-oss-osx:
	git clone https://github.com/apple/swift-package-manager
	cd swift-package-manager && git checkout 6b8ec91
	. ~/.swiftenv/init && \
		swift-package-manager/Utilities/bootstrap && \
		$(PWD)/swift-package-manager/.build/debug/swift-build && \
		$(PWD)/swift-package-manager/.build/debug/swift-test
