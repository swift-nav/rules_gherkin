load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def gherkin_deps():
    if "com_github_nelhage_rules_boost" not in native.existing_rules():
        git_repository(
            name = "com_github_nelhage_rules_boost",
            commit = "5cff96018ec4662cc61268cf248edfc6e6fe4635",
            remote = "https://github.com/nelhage/rules_boost",
            shallow_since = "1591047380 -0700",
        )
    if "gtest" not in native.existing_rules():
        git_repository(
            name = "gtest",
            commit = "703bd9caab50b139428cea1aaff9974ebee5742e",
            remote = "https://github.com/google/googletest",
        )
    if "bazelruby_rules_ruby" not in native.existing_rules():
        git_repository(
            name = "bazelruby_rules_ruby",
            branch = "master",
            remote = "https://github.com/bazelruby/rules_ruby.git",
        )
    if "bazel_skylib" not in native.existing_rules():
        http_archive(
            name = "bazel_skylib",
            urls = [
                "https://github.com/bazelbuild/bazel-skylib/releases/download/1.0.3/bazel-skylib-1.0.3.tar.gz",
                "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.0.3/bazel-skylib-1.0.3.tar.gz",
            ],
            sha256 = "1c531376ac7e5a180e0237938a2536de0c54d93f5c278634818e0efc952dd56c",
        )
    if "cucumber_cpp" not in native.existing_rules():
        # Use local cucumber-cpp with custom Bazel BUILD files
        native.local_repository(
            name = "cucumber_cpp",
            path = "third_party/cucumber-cpp",
        )
    if "rules_pkg" not in native.existing_rules():
        http_archive(
            name = "rules_pkg",
            urls = [
                "https://mirror.bazel.build/github.com/bazelbuild/rules_pkg/releases/download/0.3.0/rules_pkg-0.3.0.tar.gz",
                "https://github.com/bazelbuild/rules_pkg/releases/download/0.3.0/rules_pkg-0.3.0.tar.gz",
            ],
            sha256 = "6b5969a7acd7b60c02f816773b06fcf32fbe8ba0c7919ccdc2df4f8fb923804a",
        )
