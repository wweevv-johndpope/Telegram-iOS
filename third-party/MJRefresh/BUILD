filegroup(
    name = "Resources",
    srcs = glob([
        "Sources/MJRefresh/MJRefresh.bundle",
    ], exclude = ["Sources/MJRefresh/MJRefresh.bundle"]),
)

objc_library(
    name = "MJRefresh",
    enable_modules = True,
    module_name = "MJRefresh",
    srcs = glob([
        "Sources/MJRefresh/*.h",
        "Sources/MJRefresh/*.m",
        "Sources/MJRefresh/MJRefresh.bundle",
    ]),
    hdrs = glob([
        "Sources/MJRefresh/*.h",
    ]),
    sdk_frameworks = [
      "Foundation",
      "UIKit",
    ],
    visibility = [
        "//visibility:public",
    ],
)
