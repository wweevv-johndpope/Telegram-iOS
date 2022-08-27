load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "ProgressNavigationButtonNode",
    module_name = "ProgressNavigationButtonNode",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
        "//submodules/Display:Display",
        "//Vendor/Texture:Texture",
        "//submodules/ActivityIndicator:ActivityIndicator",
    ],
    visibility = [
        "//visibility:public",
    ],
)
