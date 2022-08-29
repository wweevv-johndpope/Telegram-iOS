load("@build_bazel_rules_apple//apple:apple.bzl",
    "apple_static_framework_import", "apple_dynamic_xcframework_import"
)


objc_library(
    name = "FirebaseAnalytics",
    deps = [":FirebaseAnalyticsXCFramework"],
    module_name = "FirebaseAnalytics",
    visibility = ["//visibility:public"],
)

apple_dynamic_xcframework_import(
    name = "FirebaseAnalyticsXCFramework",
    library_identifiers = {
        "ios_device": "ios-arm64_armv7",
        "ios_simulator": "ios-arm64_i386_x86_64-simulator",
    },
    xcframework_imports = glob(["FirebaseAnalytics/FirebaseAnalytics.xcframework/**"] ),
)




