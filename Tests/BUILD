load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

load(
    "@build_bazel_rules_apple//apple:ios.bzl",
    "ios_unit_test",
    "ios_application"
)

load(
    "@build_bazel_rules_apple//apple:macos.bzl",
    "macos_unit_test"
)

load(
    "@build_bazel_rules_apple//apple:tvos.bzl",
    "tvos_unit_test",
    "tvos_application"
)

MINIMUM_IOS_VERSION = "9.0"

MINIMUM_MACOS_VERSION = "10.9"

MINIMUM_TVOS_VERSION = "9.0"

swift_library(
    name = "KronosTests",
    srcs = glob(["KronosTests/*.swift"]),
    deps = ["//:Kronos"]
)

genrule(
    name = "AppDelegate",
    outs = ["AppDelegate.swift"],
    cmd = """
      echo "import UIKit\n\n@UIApplicationMain\nclass AppDelegate: UIResponder, UIApplicationDelegate {\nvar window: UIWindow?\n}" > $@
    """
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
    minimum_os_version = MINIMUM_IOS_VERSION,
    launch_storyboard = "Main.storyboard",
    deps = [":lib"],
)

ios_unit_test(
    name = "KronosTestsiOS",
    deps = [":KronosTests"],
    minimum_os_version = MINIMUM_IOS_VERSION,
    test_host = ":iOSTestApp"
)

macos_unit_test(
    name = "KronosTestsMacOS",
    deps = [":KronosTests"],
    minimum_os_version = MINIMUM_MACOS_VERSION
)

tvos_application(
    name = "TVOSApplication",
    bundle_id = "com.Lyft.Kronos",
    infoplists = ["Info.plist"],
    minimum_os_version = MINIMUM_TVOS_VERSION,
    deps = [":lib"],
)

tvos_unit_test(
    name = "KronosTestsTVOS",
    deps = [":KronosTests"],
    test_host = ":TVOSApplication",
    minimum_os_version = MINIMUM_TVOS_VERSION
)
