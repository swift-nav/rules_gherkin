#include <gtest/gtest.h>
#include <cucumber-cpp/autodetect.hpp>
#include <fstream>
#include <sstream>
#include <string>
#include <memory>
#include "rules_cc/cc/runfiles/runfiles.h"

using cucumber::ScenarioScope;
using rules_cc::cc::runfiles::Runfiles;

struct DataFileCtx {
  std::string filepath;
  std::string content;
};

GIVEN("^I have a data file \"(.*)\"$") {
  REGEX_PARAM(std::string, path);
  ScenarioScope<DataFileCtx> context;

  context->filepath = path;
}

WHEN("^I read the file content$") {
  ScenarioScope<DataFileCtx> context;

  // Use Bazel runfiles helper to locate the data file
  std::string error;
  std::unique_ptr<Runfiles> runfiles(Runfiles::CreateForTest(&error));
  ASSERT_NE(runfiles, nullptr) << "Failed to create runfiles: " << error;

  std::string full_path = runfiles->Rlocation(context->filepath);
  ASSERT_FALSE(full_path.empty()) << "Failed to locate file: " << context->filepath;

  std::ifstream file(full_path);
  ASSERT_TRUE(file.is_open()) << "Failed to open file: " << full_path;

  std::stringstream buffer;
  buffer << file.rdbuf();
  context->content = buffer.str();

  // Trim trailing newline if present
  if (!context->content.empty() && context->content.back() == '\n') {
    context->content.pop_back();
  }
}

THEN("^the content should be \"(.*)\"$") {
  REGEX_PARAM(std::string, expected);
  ScenarioScope<DataFileCtx> context;

  EXPECT_EQ(expected, context->content);
}
