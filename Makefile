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
