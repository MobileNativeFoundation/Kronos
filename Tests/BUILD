load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load(
    "@build_bazel_rules_apple//apple:ios.bzl",
    "ios_application",
    "ios_unit_test",
)
load(
    "@build_bazel_rules_apple//apple:macos.bzl",
    "macos_unit_test",
)

MINIMUM_IOS_VERSION = "12.0"

MINIMUM_MACOS_VERSION = "13.0"

swift_library(
    name = "KronosTests",
    testonly = True,
    srcs = glob(["KronosTests/*.swift"]),
    tags = ["manual"],
    deps = ["//:Kronos"],
)

genrule(
    name = "AppDelegate",
    outs = ["AppDelegate.swift"],
    cmd = """
      echo "import UIKit\n\n@UIApplicationMain\nclass AppDelegate: UIResponder, UIApplicationDelegate {\nvar window: UIWindow?\n}" > $@
    """,
)

swift_library(
    name = "lib",
    testonly = True,
    srcs = ["AppDelegate.swift"],
    tags = ["manual"],
)

ios_application(
    name = "iOSTestApp",
    testonly = True,
    bundle_id = "com.Lyft.Kronos",
    families = ["iphone"],
    infoplists = ["Info.plist"],
    launch_storyboard = "Main.storyboard",
    minimum_os_version = MINIMUM_IOS_VERSION,
    deps = [":lib"],
)

ios_unit_test(
    name = "KronosTestsiOS",
    minimum_os_version = MINIMUM_IOS_VERSION,
    runner = "@build_bazel_rules_apple//apple/testing/default_runner:ios_xctestrun_ordered_runner",
    test_host = ":iOSTestApp",
    deps = [":KronosTests"],
)

macos_unit_test(
    name = "KronosTestsMacOS",
    minimum_os_version = MINIMUM_MACOS_VERSION,
    deps = [":KronosTests"],
)
