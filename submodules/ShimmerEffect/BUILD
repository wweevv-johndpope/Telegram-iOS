load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "ShimmerEffect",
    module_name = "ShimmerEffect",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
        "//Vendor/Texture:Texture",
        "//submodules/Display:Display",
        "//submodules/Components/HierarchyTrackingLayer:HierarchyTrackingLayer",
    ],
    visibility = [
        "//visibility:public",
    ],
)
