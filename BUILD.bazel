load(
    "@rules_ruby//ruby:defs.bzl",
    "rb_binary",  # Updated from ruby_binary in rules_ruby 0.21.1
)

rb_binary(
    name = "cucumber_ruby",
    main = "@cucumber//bin:private/cucumber",
    visibility = ["//visibility:public"],
    deps = ["@cucumber"],
)

exports_files(
    [
        "Gemfile.lock",
        "Gemfile",
    ],
    visibility = ["//visibility:public"],
)
