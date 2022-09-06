load("@build_bazel_rules_apple//apple:apple.bzl","apple_dynamic_xcframework_import")


objc_library(
    name = "SnapKit",
    enable_modules = True,
    module_name = "SnapKit",
    deps = ["SnapKitXCFramework"],
    visibility = ["//visibility:public"]
)


apple_dynamic_xcframework_import(
    name = "SnapKitXCFramework",
    xcframework_imports = glob(["SnapKit.xcframework/**"] ),
    library_identifiers = {
          "ios_device": "ios-arm64_armv7",
        "ios_simulator": "ios-arm64_i386_x86_64-simulator",
    },
    deps = [],
    visibility = ["//visibility:public"],
#      infoplists = ["//submodules/TelegramUI/Supabase/PostgREST.xcframework:Info.plist"]
)
