load("@rules_gherkin//gherkin:defs.bzl", "gherkin_library", "gherkin_test")

gherkin_library(
    name = "feature_specs",
    srcs = glob(["**/*.feature"]),
)

gherkin_test(
    name = "calc_test",
    steps = "//Calc/features/step_definitions:calculator_steps",
    deps = [":feature_specs"],
)
