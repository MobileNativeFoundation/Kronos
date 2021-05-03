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

MINIMUM_IOS_VERSION = "9.0"

MINIMUM_MACOS_VERSION = "10.9"

swift_library(
    name = "KronosTests",
    srcs = glob(["KronosTests/*.swift"]),
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
    srcs = ["AppDelegate.swift"],
)

ios_application(
    name = "iOSTestApp",
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
    test_host = ":iOSTestApp",
    deps = [":KronosTests"],
)

macos_unit_test(
    name = "KronosTestsMacOS",
    minimum_os_version = MINIMUM_MACOS_VERSION,
    deps = [":KronosTests"],
)
