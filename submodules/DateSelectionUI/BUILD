load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "DateSelectionUI",
    module_name = "DateSelectionUI",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//Vendor/Texture:Texture",
        "//submodules/Display:Display",
        "//submodules/AccountContext:AccountContext",
        "//submodules/TelegramStringFormatting:TelegramStringFormatting",
        "//submodules/TelegramPresentationData:TelegramPresentationData",
        "//submodules/UIKitRuntimeUtils:UIKitRuntimeUtils",
    ],
    visibility = [
        "//visibility:public",
    ],
)
