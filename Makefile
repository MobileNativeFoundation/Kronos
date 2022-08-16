# Install Tasks

install-iOS:
	true

install-OSX:
	true

install-tvOS:
	true

install-lint:
	brew install swiftlint || true

# Run Tasks

test-lint:
	swiftlint lint --strict 2>/dev/null

test-iOS:
	set -o pipefail && \
		xcodebuild \
		-project Kronos.xcodeproj \
		-scheme Kronos \
		-destination "name=iPhone 11 Pro Max" \
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
		-destination "platform=tvOS Simulator,name=Apple TV" \
		test \
		| xcpretty -ct
