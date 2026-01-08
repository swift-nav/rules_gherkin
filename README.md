![bazel_cucumber](doc/imgs/bazel_cucumber.png)
![Bazel](https://github.com/swift-nav/rules_gherkin/workflows/Bazel/badge.svg) [![docs](https://img.shields.io/badge/docs-latest-brightgreen.svg?style=flat)](https://swift-nav.github.io/rules_gherkin/)
# rules_gherkin
A set of bazel rules for BDD with [cucumber/gherkin](https://cucumber.io/).

## Getting started

### Prerequisites
You'll need a `Gemfile` and `Gemfile.lock` in the root of your workspace with the following content:

```ruby
source 'https://rubygems.org'

gem 'cucumber', '~> 10.2.0'
gem 'cucumber-wire', '~> 8.0.0'
```

Run `bundle install` to generate the `Gemfile.lock` file.

### MODULE.bazel Setup
Add the following to your `MODULE.bazel` (see examples/MODULE.bazel for complete example):

```python
bazel_dep(name = "rules_gherkin", version = "0.1.0")
bazel_dep(name = "rules_ruby", version = "0.21.1")

ruby = use_extension("@rules_ruby//ruby:extensions.bzl", "ruby")
ruby.toolchain(
    name = "ruby",
    version = "jruby-9.4.5.0",
)
ruby.bundle_fetch(
    name = "cucumber",
    gem_checksums = { ... },  # See examples/MODULE.bazel for complete checksums
    gemfile = "//:Gemfile",
    gemfile_lock = "//:Gemfile.lock",
)
use_repo(ruby, "cucumber", "ruby", "ruby_toolchains")

register_toolchains("@ruby_toolchains//:all")
```

Note: The `gem_checksums` dictionary is required for hermetic builds. See `examples/MODULE.bazel` for the complete list of checksums.

### BUILD.bazel Example
Create a `BUILD.bazel` file in your feature directory:

```python
load("@rules_gherkin//gherkin:defs.bzl", "gherkin_library", "gherkin_test", "cc_gherkin_steps")

# Define your feature files
gherkin_library(
    name = "feature_specs",
    srcs = glob(["**/*.feature"]),
)

# Define step implementations in C++
cc_gherkin_steps(
    name = "calculator_steps",
    srcs = [
        "CalculatorSteps.cpp",
    ],
    visibility = ["//visibility:public"],
    deps = [
        "//Calc/src:calculator",
        "@cucumber-cpp//:cucumber-cpp",
        "@googletest//:gtest_main",
    ],
)

# Create test target
gherkin_test(
    name = "calc_test",
    steps = ":calculator_steps",
    deps = [":feature_specs"],
)
```

## Configuration Options

### Output Format
You can configure the cucumber output format using the `--@rules_gherkin//:cucumber_format` flag:

```bash
bazel test //path/to:test --@rules_gherkin//:cucumber_format=json
```

Available formats:
- `pretty` (default) - Human-readable output
- `json` - JSON format
- `html` - HTML report
- `junit` - JUnit XML format

## Attribution
Big thank you to 'Paolo Ambrosio', who authored the [cucumber-cpp](https://github.com/cucumber/cucumber-cpp) from whom I copied and modified the //examples directory in this repository. The examples/LICENCE.txt has been added to reflect the origins of the example.
