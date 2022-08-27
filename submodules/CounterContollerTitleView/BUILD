load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "CounterContollerTitleView",
    module_name = "CounterContollerTitleView",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
        "//Vendor/Texture:Texture",
        "//submodules/Display:Display",
        "//submodules/TelegramPresentationData:TelegramPresentationData",
    ],
    visibility = [
        "//visibility:public",
    ],
)
