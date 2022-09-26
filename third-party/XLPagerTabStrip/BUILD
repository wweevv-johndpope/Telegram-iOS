objc_library(
    name = "XLPagerTabStrip",
    enable_modules = True,
    module_name = "XLPagerTabStrip",
    srcs = glob([
        "Sources/*.m",
        "Sources/*.h",
    ]),
    data = glob([
        "Sources/*.swift",
        "Sources/*.xib",
     ]),
    hdrs = glob([
        "Sources/*.h",
    ]),
    includes = [
      "PublicHeaders",
    ],
    sdk_frameworks = [
      "Foundation",
      "UIKit",
      "CoreGraphics",
    ],
    visibility = [
        "//visibility:public",
    ],
)