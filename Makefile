# Install Tasks

install-lint:
	brew install swiftlint || true

install-%:
	true

# Run Tasks

test-lint:
	swiftlint lint --strict 2>/dev/null

test-iOS:
	set -o pipefail && \
		xcodebuild \
		-project Kronos.xcodeproj \
		-scheme Kronos \
		-destination "name=iPhone 11 Pro Max" \
		test

test-OSX:
	set -o pipefail && \
		xcodebuild \
		-project Kronos.xcodeproj \
		-scheme Kronos \
		test

test-tvOS:
	set -o pipefail && \
		xcodebuild \
		-project Kronos.xcodeproj \
		-scheme Kronos \
		-destination "platform=tvOS Simulator,name=Apple TV,OS=13.3" \
		test
