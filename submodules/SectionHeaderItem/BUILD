load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "SectionHeaderItem",
    module_name = "SectionHeaderItem",
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
        "//submodules/TelegramPresentationData:TelegramPresentationData",
        "//submodules/ItemListUI:ItemListUI",
        "//submodules/ListSectionHeaderNode:ListSectionHeaderNode",
    ],
    visibility = [
        "//visibility:public",
    ],
)
