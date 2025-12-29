![bazel_cucumber](doc/imgs/bazel_cucumber.png)
![Bazel](https://github.com/silvergasp/rules_gherkin/workflows/Bazel/badge.svg) [![docs](https://img.shields.io/badge/docs-latest-brightgreen.svg?style=flat)](https://silvergasp.github.io/rules_gherkin/)
# rules_gherkin
A set of bazel rules for BDD with [cucumber/gherkin](https://cucumber.io/).

NOTE: This is alpha level software, the API may change without notice.

## Getting started
Add the following to your `MODULE.bazel` (see examples/MODULE.bazel):

``` python
bazel_dep(name = "rules_gherkin", version = "0.1.0")
bazel_dep(name = "rules_ruby", version = "0.21.1")

ruby = use_extension("@rules_ruby//ruby:extensions.bzl", "ruby")
ruby.toolchain(
    name = "ruby",
    version = "jruby-9.4.5.0",
)
ruby.bundle_fetch(
    name = "cucumber",
    gemfile = "//:Gemfile",
    gemfile_lock = "//:Gemfile.lock",
)
use_repo(ruby, "cucumber", "ruby", "ruby_toolchains")

register_toolchains("@ruby_toolchains//:all")

```
Example `BUILD.bazel` file.

```python
load("//gherkin:defs.bzl", "gherkin_library", "gherkin_test")

gherkin_library(
    name = "feature_specs",
    srcs = glob(["**/*.feature"]),
)

gherkin_test(
    name = "calc_test",
    steps = ":calculator_steps",
    deps = [":feature_specs"],
)

load("//gherkin:defs.bzl", "cc_gherkin_steps")

cc_gherkin_steps(
    name = "calculator_steps",
    srcs = [
        "CalculatorSteps.cpp",
    ],
    visibility = ["//visibility:public"],
    deps = [
        "//Calc/src:calculator",
        "@cucumber-cpp//:cucumber_main",
        "@googletest//:gtest_main",
    ],
)
```

## Attribution
Big thank you to 'Paolo Ambrosio', who authored the [cucumber-cpp](https://github.com/cucumber/cucumber-cpp) from whom I copied and modified the //examples directory in this repository. The examples/LICENCE.txt has been added to reflect the origins of the example.
