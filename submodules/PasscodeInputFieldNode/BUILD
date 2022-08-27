load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "PasscodeInputFieldNode",
    module_name = "PasscodeInputFieldNode",
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
    ],
    visibility = [
        "//visibility:public",
    ],
)
