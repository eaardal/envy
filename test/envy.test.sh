#!/bin/bash

# Source envy so we can call functions directly.
# The no operation (noop) command will do nothing, allowing us to source the script without side effects.
source ../envy noop

# Verifying command output: https://github.com/kward/shunit2/wiki/Cookbook#verifying-command-output
# More examples: https://github.com/kward/shunit2/blob/master/examples/output_test.sh

announce() {
  printf "\t%s\n" "$1"
}

oneTimeSetUp() {
  # Define global variables for command output.
  STDOUT="${SHUNIT_TMPDIR}/stdout"
  STDERR="${SHUNIT_TMPDIR}/stderr"
}

setUp() {
  # Truncate the output files.
  cp /dev/null "${STDOUT}"
  cp /dev/null "${STDERR}"
}

showOutput() {
  # shellcheck disable=SC2166
  if [ -n "${STDOUT}" -a -s "${STDOUT}" ]; then
    echo '>>> STDOUT' >&2
    cat "${STDOUT}" >&2
    echo '<<< STDOUT' >&2
  fi
  # shellcheck disable=SC2166
  if [ -n "${STDERR}" -a -s "${STDERR}" ]; then
    echo '>>> STDERR' >&2
    cat "${STDERR}" >&2
    echo '<<< STDERR' >&2
  fi
}

# https://github.com/kward/shunit2/blob/master/examples/output_test.sh#L10
execCommand() {
  local cmd=$*
  ($cmd) > "$STDOUT" 2> "$STDERR"
}

test_extract_env() {
  message="should extract env name and value when line is only key=value" && announce "$message"
  result=$(extract_env "foo=bar")
  expected="{\"key\":\"foo\",\"value\":\"bar\"}"
  actual=$result
  assertEquals "$message" "$expected" "$actual"

  message="should extract env name and value when line starts with 'export'" && announce "$message"
  result=$(extract_env "export foo=bar")
  expected="{\"key\":\"foo\",\"value\":\"bar\"}"
  actual=$result
  assertEquals "$message" "$expected" "$actual"

  message="should return null if line starts with comment (#)"
  result=$(extract_env "# export foo=bar")
  expected=null
  actual=$result
  assertEquals "$message" "$expected" "$actual"

  message="should return env name and value if line ends with a comment (#)" && announce "$message"
  result=$(extract_env "foo=bar # this is a comment")
  expected="{\"key\":\"foo\",\"value\":\"bar\"}"
  actual=$result
  assertEquals "$message" "$expected" "$actual"

  message="should return correct env value when value includes special characters" && announce "$message"
  result=$(extract_env "foo=bar+-_==")
  expected="{\"key\":\"foo\",\"value\":\"bar+-_==\"}"
  actual=$result
  assertEquals "$message" "$expected" "$actual"
}

test_envy_yaml_command_when_yaml_is_plain_text() {
  message="should list all envs in yaml file" && announce "$message"
  result=$(ENVY_YAML=./testdata/envy-test-default.yaml yaml)
  expected='names:
  - first.section
  - second.section.group
first:
  section:
    MY_ENV: foo
    OTHER_ENV: bar
second:
  section:
    group:
      GROUP_ENV: aaa'
  actual=$result
  assertEquals "$message" "$expected" "$actual"
}

test_envy_yaml_command_when_yaml_contains_references() {
  message="should print full yaml file with references/aliases" && announce "$message"
  result=$(ENVY_YAML=./testdata/envy-test-references.yaml yaml)
  expected='names:
  - first.section
  - second.section.group
first:
  section:
    MY_ENV: foo
    OTHER_ENV: bar
second:
  section:
    MY_ENV: foo
    OTHER_ENV: bar
    group:
      GROUP_ENV: aaa
      OTHER_GROUP_ENV: aaa'
  actual=$result
  assertEquals "$message" "$expected" "$actual"
}

test_envy_yaml_command_with_raw_flag() {
  message="should print raw yaml file without resolving references/aliases" && announce "$message"
  result=$(ENVY_YAML=./testdata/envy-test-references.yaml yaml --raw)
  expected='names:
  - first.section
  - second.section.group
first:
  section: &first-section
    MY_ENV: foo
    OTHER_ENV: bar
second:
  section:
    <<: *first-section
    group:
      GROUP_ENV: &group-env aaa
      OTHER_GROUP_ENV: *group-env'
  actual=$result
  assertEquals "$message" "$expected" "$actual"
}

test_envy_list_command() {
  message="should print environment names" && announce "$message"
  result=$(ENVY_YAML=./testdata/envy-test-default.yaml list)
  container=$result
  assertContains "$message" "$container" "first.section"
  assertContains "$message" "$container" "second.section.group"
}

test_envy_show_command() {
  local message="should print the key and value for the environment variable at the given path" && announce "$message"

  local match

  (ENVY_YAML=./testdata/envy-test-default.yaml ../envy show first.section) > "$STDOUT" 2> "$STDERR"

  local result=$?
  assertTrue "Command exited with an error" $result

  # Show command result if it returned a non-ok exit code
  [ $result -gt 0 ] && showOutput

  local expected="MY_ENV: foo\nOTHER_ENV: bar"
  match=$(pcregrep -M "$expected" "$STDOUT" | wc -c)
  assertTrue "Command output is not exact match" "[ $match -gt 0 ]"
}

test_commented_yaml() {
  local message="should handle commented lines" && printf "\t%s" "$message"
  local line="foo=bar"

  # if [[ $line == "#"* ]]
  # then
  #   echo "line starts with #"
  # else
  #   echo "line does not start with #"
  # fi

  if [[ "$line" =~ ^(?:export\s)?([\w]+)=([\w\d\=\+\-\_]+) ]]
  then
    echo "line is a kvp line"
  else
    echo "line is NOT a kvp line"
  fi
}

# Load shUnit2 which will run all functions prefixed with "test"
# https://github.com/kward/shunit2
# shellcheck source=/Users/eaardal/dev/apps/shunit2/shunit2
. shunit2
