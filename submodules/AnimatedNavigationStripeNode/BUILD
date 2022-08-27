load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "AnimatedNavigationStripeNode",
    module_name = "AnimatedNavigationStripeNode",
    srcs = glob([
		"Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
        "//submodules/Display:Display",
        "//Vendor/Texture:Texture",
    ],
    visibility = [
        "//visibility:public",
    ],
)
