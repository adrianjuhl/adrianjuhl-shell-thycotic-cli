#!/usr/bin/env bash

# Validates that the thycotic_cli.sh script passes shellspec and shellcheck.

usage()
{
  cat <<USAGE_TEXT
Usage:  ${THIS_SCRIPT_NAME}
            [--file_source_location=<working_directory|staging_area>]
            [--help | -h]
            [--script_debug]

Validates that the thycotic_cli.sh script passes shellspec and shellcheck.

Available options:
    --file_source_location=<working_directory|staging_area>
        The location from where to retrieve the script for testing.
        Valid values:
          - working_directory     Take the file from the working directory. (default)
          - staging_area          Take the file from the git staging area.
    --help, -h
        Print this help and exit.
    --script_debug
        Print script debug info.
USAGE_TEXT
}

main()
{
  initialize
  parse_script_params "${@}"
  test_thycotic_cli
}

test_thycotic_cli()
{
  echo "Test script '${THIS_SCRIPT_NAME}' running... (validates that the script passes shellspec and shellcheck)"
  get_project_root_directory
  cd_to_project_root_directory
  init_test_context
  shellspec_script
  shellcheck_script
  report_all_errors
  exit_with_error_code_if_any_errors_occurred
}

get_project_root_directory()
{
  project_root_directory="$(git rev-parse --show-toplevel)" || { echo "Error: Failed to determine the project root directory."; abort_script; }
}

cd_to_project_root_directory()
{
  cd "${project_root_directory}" || { echo "Error: Failed to cd into project root directory."; abort_script; }
}

init_test_context()
{
  ERROR_CODES=()
  ERROR_MESSAGES=()
  TEST_DATETIME="$(date +%Y%m%d%H%M%S)"
  TEST_WORKING_DIRECTORY="/tmp/thycotic_cli_testing/${TEST_DATETIME}"
  prepare_test_working_directory
}

shellspec_script()
{
  echo
  echo "Checking script with shellspec ..."
  cd "${TEST_WORKING_DIRECTORY}" || exit 1
  shellspec \
      --kcov \
      --format=documentation
  RESULT=$?
  if [ ${RESULT} -ne 0 ]; then
    ERROR_CODE="ef7bf6de-bea8-4850-8805-ee05262fc9ca"
    ERROR_MESSAGE="The script did not pass shellspec. (Error code ${ERROR_CODE})"
    ERROR_MESSAGES+=("${ERROR_MESSAGE}")
    ERROR_CODES+=("${ERROR_CODE}")
  fi
  echo "working directory: ${TEST_WORKING_DIRECTORY}"
  echo "working directory content:"
  ls -al "${TEST_WORKING_DIRECTORY}"
  echo "file://${TEST_WORKING_DIRECTORY}/coverage/index.html"
  echo "Completed shellspec."
}

shellcheck_script()
{
  echo
  echo "Checking script with shellcheck ..."
  cd "${TEST_WORKING_DIRECTORY}" || exit 1
  shellcheck --external-sources bin/thycotic_cli.sh
  RESULT=$?
  if [ ${RESULT} -ne 0 ]; then
    ERROR_CODE="99054f2a-f8c9-49b4-8713-f44aa731b716"
    ERROR_MESSAGE="The script did not pass shellcheck. (Error code ${ERROR_CODE})"
    ERROR_MESSAGES+=("${ERROR_MESSAGE}")
    ERROR_CODES+=("${ERROR_CODE}")
  fi
  echo "Completed shellcheck."
}

prepare_test_working_directory()
{
  mkdir -p "${TEST_WORKING_DIRECTORY}"
  mkdir -p "${TEST_WORKING_DIRECTORY}/bin"
  mkdir -p "${TEST_WORKING_DIRECTORY}/spec"
  if [ "${file_source_location}" == "working_directory" ]; then
    cp .shellspec "${TEST_WORKING_DIRECTORY}/.shellspec"
    cp bin/thycotic_cli.sh "${TEST_WORKING_DIRECTORY}/bin/thycotic_cli.sh"
    cp -r spec "${TEST_WORKING_DIRECTORY}"
  fi
  if [ "${file_source_location}" == "staging_area" ]; then
    git show :.shellspec > "${TEST_WORKING_DIRECTORY}/.shellspec"
    git show :bin/thycotic_cli.sh > "${TEST_WORKING_DIRECTORY}/bin/thycotic_cli.sh"
    git show :spec/spec_helper.sh > "${TEST_WORKING_DIRECTORY}/spec/spec_helper.sh"
    git show :spec/thycotic_cli_spec.sh > "${TEST_WORKING_DIRECTORY}/spec/thycotic_cli_spec.sh"
    chmod u+x "${TEST_WORKING_DIRECTORY}/bin/thycotic_cli.sh"
  fi
}

report_all_errors()
{
  for message in "${ERROR_MESSAGES[@]}"; do
    echo "[ERROR] '${THIS_SCRIPT_NAME}' found the following error:"
    echo "${message}"
  done
}

exit_with_error_code_if_any_errors_occurred()
{
  # If any error code isn't 0, exit with that error code.
  for ERROR_CODE in "${ERROR_CODES[@]}"; do
    [ "${ERROR_CODE}" == "" ] || { echo "[ERROR] '${THIS_SCRIPT_NAME}' found the above error(s)" && exit 5; }
  done
}

parse_script_params()
{
  #msg "script params (${#}) are: ${@}"
  # default values of variables set from params
  file_source_location="working_directory"
  SCRIPT_DEBUG_OPTION="${FALSE_STRING}"
  while [ "${#}" -gt 0 ]
  do
    case "${1-}" in
      --file_source_location=*)
        file_source_location="${1#*=}"
        ;;
      --help | -h)
        usage
        exit
        ;;
      --script_debug)
        set -x
        SCRIPT_DEBUG_OPTION="${TRUE_STRING}"
        ;;
      -?*)
        echo "Error: Unknown parameter: ${1}"
        echo "Use --help for usage help"
        abort_script
        ;;
      *) break ;;
    esac
    shift
  done
  if [ -z "${file_source_location}" ]; then
    echo "Error: Missing required parameter: some_parameter"
    abort_script
  fi
  case "${file_source_location}" in
    working_directory)
      ;;
    staging_area)
      ;;
    *)
      echo "Error: Invalid file_source_location value: '${file_source_location}', expected one of: working_directory, staging_area"
      abort_script
      ;;
  esac
}

initialize()
{
  set -o pipefail
  THIS_SCRIPT_PROCESS_ID=$$
  initialize_abort_script_config
  initialize_this_script_directory_variable
  initialize_this_script_name_variable
  initialize_true_and_false_strings
}

initialize_abort_script_config()
{
  # Exit shell script from within the script or from any subshell within this script - adapted from:
  # https://cravencode.com/post/essentials/exit-shell-script-from-subshell/
  # Exit with exit status 1 if this (top level process of this script) receives the SIGUSR1 signal.
  # See also the abort_script() function which sends the signal.
  trap "exit 1" SIGUSR1
}

initialize_this_script_directory_variable()
{
  # Determines the value of THIS_SCRIPT_DIRECTORY, the absolute directory name where this script resides.
  # See: https://www.binaryphile.com/bash/2020/01/12/determining-the-location-of-your-script-in-bash.html
  # See: https://stackoverflow.com/a/67149152
  local last_command_return_code
  THIS_SCRIPT_DIRECTORY=$(cd "$(dirname -- "${BASH_SOURCE[0]}")" || exit 1; cd -P -- "$(dirname "$(readlink -- "${BASH_SOURCE[0]}" || echo .)")" || exit 1; pwd)
  last_command_return_code="$?"
  if [ "${last_command_return_code}" -gt 0 ]; then
    # This should not occur for the above command pipeline.
    echo
    echo "Error: Failed to determine the value of this_script_directory."
    echo
    abort_script
  fi
}

initialize_this_script_name_variable()
{
  local path_to_invoked_script
  local default_script_name
  path_to_invoked_script="${BASH_SOURCE[0]}"
  default_script_name=""
  if grep -q '/dev/fd' <(dirname "${path_to_invoked_script}"); then
    # The script was invoked via process substitution
    if [ -z "${default_script_name}" ]; then
      THIS_SCRIPT_NAME="<script invoked via file descriptor (process substitution) and no default name set>"
    else
      THIS_SCRIPT_NAME="${default_script_name}"
    fi
  else
    THIS_SCRIPT_NAME="$(basename "${path_to_invoked_script}")"
  fi
}

initialize_true_and_false_strings()
{
  # Bash doesn't have a native true/false, just strings and numbers,
  # so this is as clear as it can be, using, for example:
  # if [ "${my_boolean_var}" = "${TRUE_STRING}" ]; then
  # where previously 'my_boolean_var' is set to either ${TRUE_STRING} or ${FALSE_STRING}
  TRUE_STRING="true"
  FALSE_STRING="false"
}

abort_script()
{
  echo >&2 "aborting..."
  kill -SIGUSR1 ${THIS_SCRIPT_PROCESS_ID}
  exit
}

# Main entry into the script - call the main() function
main "${@}"
