# language: en
Feature: Data File Reading
  In order to verify runfiles work correctly
  As a test framework user
  I want to read data from a file dependency

  Scenario: Read content from data file
    Given I have a data file "_main/DataFile/testdata.txt"
    When I read the file content
    Then the content should be "42"
