load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "SolidRoundedButtonNode",
    module_name = "SolidRoundedButtonNode",
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
        "//submodules/ShimmerEffect:ShimmerEffect",
        "//submodules/Components/HierarchyTrackingLayer:HierarchyTrackingLayer",
        "//submodules/ManagedAnimationNode:ManagedAnimationNode",
    ],
    visibility = [
        "//visibility:public",
    ],
)
