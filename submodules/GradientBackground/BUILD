load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "GradientBackground",
    module_name = "GradientBackground",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-O",
        "-warnings-as-errors",
    ],
    deps = [
        "//Vendor/Texture:Texture",
        "//submodules/Display:Display",
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
    ],
    visibility = [
        "//visibility:public",
    ],
)
