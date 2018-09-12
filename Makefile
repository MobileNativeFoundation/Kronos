# Install Tasks

install-iOS:
	true

install-OSX:
	true

install-tvOS:
	true

install-lint:
	brew remove swiftlint --force || true
	brew install --force-bottle https://raw.githubusercontent.com/Homebrew/homebrew-core/a97c85994a3f714355a20511b4df3a546ae809cf/Formula/swiftlint.rb

# Run Tasks

test-lint:
	swiftlint lint --strict 2>/dev/null

test-iOS:
	set -o pipefail && \
		xcodebuild \
		-project Kronos.xcodeproj \
		-scheme Kronos \
		-destination "name=iPhone X" \
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
		-destination "platform=tvOS Simulator,name=Apple TV,OS=12.0" \
		test \
		| xcpretty -ct
