load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "AuthorizationUI",
    module_name = "AuthorizationUI",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
        "//Vendor/Texture:Texture",
        "//submodules/TelegramCore:TelegramCore",
        "//submodules/Display:Display",
        "//submodules/TextFormat:TextFormat",
        "//submodules/Markdown:Markdown",
        "//submodules/TelegramPresentationData:TelegramPresentationData",
    ],
    visibility = [
        "//visibility:public",
    ],
)
