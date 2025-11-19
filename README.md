![bazel_cucumber](doc/imgs/bazel_cucumber.png)
![Bazel](https://github.com/silvergasp/rules_gherkin/workflows/Bazel/badge.svg) [![docs](https://img.shields.io/badge/docs-latest-brightgreen.svg?style=flat)](https://silvergasp.github.io/rules_gherkin/)
# rules_gherkin
A set of bazel rules for BDD with [cucumber/gherkin](https://cucumber.io/).

NOTE: This is alpha level software, the API may change without notice

## Getting started
Add the following to your WORKSPACE

``` python
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")
git_repository(
    name = "rules_gherkin",
    commit = "ef361f40f9716ad8a3c6a8a21111bb80d4cbd927", # Update this to match latest commit
    remote = "https://github.com/silvergasp/rules_gherkin.git"
)
load("@rules_gherkin//:gherkin_deps.bzl","gherkin_deps")
gherkin_deps()

load("@rules_gherkin//:gherkin_workspace.bzl","gherkin_workspace")
gherkin_workspace()
```
Example BUILD file.

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
        "//examples/Calc/src:calculator",
        "@cucumber-cpp//src:cucumber_main",
        "@gtest",
    ],
)


```

## Attribution
Big thank you to 'Paolo Ambrosio', who authored the [cucumber-cpp](https://github.com/cucumber/cucumber-cpp) from whom I copied and modified the //examples directory in this repository. The examples/LICENCE.txt has been added to reflect the origins of the example.
