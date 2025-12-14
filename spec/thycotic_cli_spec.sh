
script_under_test="bin/thycotic_cli.sh"

json_element_base64_decoded_should_include() {
  element_value="$(jq -e -r "${1}")" || { echo >&2 "Error: Failed to get element ${1}"; return 1; }
  plain_text="$(base64 --decode <<<"${element_value}")" || { echo >&2 "Error: Failed to base64 decode element ${1}"; return 1; }
  echo "${plain_text}" | grep "${2}" >/dev/null
  last_command_return_code="$?"
  if [ "${last_command_return_code}" -gt 0 ]; then
    echo >&2 "json_element_base64_decoded_should_include failed"
    echo >&2 "input: >>${json_element_base64_decoded_should_include}<<"
    echo >&2 "element_value: >>${element_value}<<"
    echo >&2 "plain_text: ${plain_text}"
    return 1
  fi
}

setup() {
  # Clear existing THYCOTIC_* envvars.
  unset THYCOTIC_CLI_THYCOTIC_HOST_URL
  unset THYCOTIC_CLI_USERNAME
  unset THYCOTIC_CLI_GET_USERNAME_COMMAND
  unset THYCOTIC_CLI_GET_PASSWORD_COMMAND
  THYCOTIC_CLI_THYCOTIC_HOST_URL="dummy"
  export THYCOTIC_CLI_THYCOTIC_HOST_URL
}

BeforeAll "setup"

Describe "--version is a parameter"
  It "should output version information"
    When run script "${script_under_test}" --version
    The stdout should include "thycotic_cli version 0.8.0"
    The status should equal 0
  End
End

Describe "usage"
  It "should output usage information"
    When run script "${script_under_test}" --help
    The stdout should include "Usage:"
    The stdout should include "thycotic_cli.sh"
    The stdout should include "Available commands:"
    The stdout should include "General parameters:"
    The status should equal 0
  End
End

Describe "usage_get_secret"
  It "should output usage information"
    When run script "${script_under_test}" get_secret --help
    The stdout should include "Usage:"
    The stdout should include "get_secret <args>"
    The stdout should include "Get a secret."
    The stdout should include "Parameters:"
    The stdout should include "--secret_id=<id>"
    The stdout should include "The ID of the secret to return (required)"
    The status should equal 0
  End
End

Describe "usage_get_secret_field_value"
  It "should output usage information"
    When run script "${script_under_test}" get_secret_field_value --help
    The stdout should include "Usage:"
    The stdout should include "get_secret_field_value <args>"
    The stdout should include "Get the value of a field of a secret."
    The stdout should include "Parameters:"
    The stdout should include "--secret_id=<id>"
    The stdout should include "The ID of the secret to return (required)"
    The stdout should include "--field_slug=<slug>"
    The stdout should include "The field 'slug' of the 'SecretItem' of the secret to return (required)"
    The status should equal 0
  End
End

Describe "usage_authenticate"
  It "should output usage information"
    When run script "${script_under_test}" authenticate --help
    The stdout should include "Usage:"
    The stdout should include "authenticate"
    The stdout should include "Get an API access token."
    The stdout should include "Use the following to save the token:"
    The stdout should include "$ export THYCOTIC_CLI_THYCOTIC_API_ACCESS_TOKEN=\"\$(thycotic_cli.sh authenticate)\""
    The status should equal 0
  End
End

Describe "when the script is called with an unknown command"
  It "should exit with failure status and output error message"
    When run script "${script_under_test}" this_is_not_a_thycotic_cli_command
    The status should be failure
    The stderr should include "Error: Unknown command: this_is_not_a_thycotic_cli_command"
    The stderr should include "Use --help for usage help"
  End
End

Describe "when the script is called with command get_secret with an unknown parameter"
  It "should exit with failure status and output error message"
    When run script "${script_under_test}" get_secret --unknownparameter
    The status should be failure
    The stderr should include "Error: Unknown get_secret parameter: --unknownparameter"
    The stderr should include "Use --help for usage help"
  End
End

Describe "when the script is called with command get_secret_field_value with an unknown parameter"
  It "should exit with failure status and output error message"
    When run script "${script_under_test}" get_secret_field_value --unknownparameter
    The status should be failure
    The stderr should include "Error: Unknown get_secret_field_value parameter: --unknownparameter"
    The stderr should include "Use --help for usage help"
  End
End

Describe "when the script is called with command authenticate with an unknown parameter"
  It "should exit with failure status and output error message"
    When run script "${script_under_test}" authenticate --unknownparameter
    The status should be failure
    The stderr should include "Error: Unknown authenticate parameter: --unknownparameter"
    The stderr should include "Use --help for usage help"
  End
End

Describe "run_script_with_script_debug"
  It "should output usage information"
    When run script "${script_under_test}" --script_debug authenticate --help
    The status should equal 0
    The stdout should include "Usage:"
    #The stderr should be present # The presence of stderr depends on whether or not xtrace ('set -x') is set.
  End
End

Describe "ensure_thycotic_api_access_token_is_held"
  Include "${script_under_test}"
  Include "/usr/local/bin/capture_stdout_and_stderr.sh"
  do_before_0() {
    initialize_true_and_false_strings
  }
  Before "do_before_0"
  Describe "when the variable THYCOTIC_CLI_THYCOTIC_API_ACCESS_TOKEN has the value of an existing token"
    do_before_1() {
      THYCOTIC_CLI_THYCOTIC_API_ACCESS_TOKEN="an_access_token"
      export THYCOTIC_CLI_THYCOTIC_API_ACCESS_TOKEN
    }
    Before "do_before_1"
    Describe "when validation of the existing token indicates invalid token"
      do_before_2() {
        thycotic_get_connection_manager_settings_curl_stderr='___CURL_OUTPUT___CURL_INFORMATION_JSON___{"http_code":"123"}'
        thycotic_get_connection_manager_settings_curl_command() { echo >&2 "${thycotic_get_connection_manager_settings_curl_stderr}"; return 0; }
      }
      Before "do_before_2"
      Describe "then a new token will be obtained"
        do_before_3() {
          get_user_username() { THYCOTIC_USER_USERNAME="myusername"; return 0; }
          get_user_password() { THYCOTIC_USER_PASSWORD="mypassword"; return 0; }
        }
        Before "do_before_3"
        Describe "when getting a new token succeeds"
          do_before_4() {
            thycotic_authenticate_curl_fake_stdout='{"access_token":"the_new_access_token"}'
            thycotic_authenticate_curl_fake_stderr='___CURL_OUTPUT___CURL_INFORMATION_JSON___{"http_code":"200"}'
            thycotic_authenticate_curl_command() { echo "${thycotic_authenticate_curl_fake_stdout}"; echo >&2 "${thycotic_authenticate_curl_fake_stderr}"; return 0; }
          }
          Before "do_before_4"
          It "should succeed and the variable THYCOTIC_CLI_THYCOTIC_API_ACCESS_TOKEN should contain the value of the newly obtained token"
            When call ensure_thycotic_api_access_token_is_held
            The status should be success
            The stderr should include "Warning: The provided Thycotic API Access Token is invalid or expired and won't be used."
            The stderr should include "The HTTP status code for the token validation to Thycotic was: 123  (expected 200)."
            The variable THYCOTIC_CLI_THYCOTIC_API_ACCESS_TOKEN should equal "the_new_access_token"
          End
        End
        Describe "when getting a new token fails"
          do_before_4() {
            thycotic_authenticate_curl_command() { return 1; }
          }
          Before "do_before_4"
          It "should fail and report an error"
            When call ensure_thycotic_api_access_token_is_held
            The status should be failure
            The stderr should include "Error: Failed to get an access token."
            The variable THYCOTIC_CLI_THYCOTIC_API_ACCESS_TOKEN should be undefined
          End
        End
      End
    End
    Describe "when validation of the existing token fails"
      do_before_2() {
        validate_thycotic_api_access_token() { return 1; }
      }
      Before "do_before_2"
      It "should fail and report an error"
        When call ensure_thycotic_api_access_token_is_held
        The status should be failure
        The stderr should include "Error: Failed to validate the existing access token."
      End
    End
    Describe "when validation of the existing token succeeds and indicates valid token"
      do_before_2() {
        thycotic_get_connection_manager_settings_curl_stderr='___CURL_OUTPUT___CURL_INFORMATION_JSON___{"http_code":"200"}'
        thycotic_get_connection_manager_settings_curl_command() { echo >&2 "${thycotic_get_connection_manager_settings_curl_stderr}"; return 0; }
      }
      Before "do_before_2"
      It "should succeed and the value of THYCOTIC_CLI_THYCOTIC_API_ACCESS_TOKEN should remain the same"
        When call ensure_thycotic_api_access_token_is_held
        The status should be success
        The variable THYCOTIC_CLI_THYCOTIC_API_ACCESS_TOKEN should equal "an_access_token"
      End
    End
  End
  Describe "when the variable THYCOTIC_CLI_THYCOTIC_API_ACCESS_TOKEN is not set"
    do_before_1() {
      unset THYCOTIC_CLI_THYCOTIC_API_ACCESS_TOKEN
    }
    Before "do_before_1"
    Describe "then a new token will be obtained"
      do_before_2() {
        get_user_username() { THYCOTIC_USER_USERNAME="myusername"; return 0; }
        get_user_password() { THYCOTIC_USER_PASSWORD="mypassword"; return 0; }
      }
      Before "do_before_2"
      Describe "when getting a new token succeeds"
        do_before_3() {
          thycotic_authenticate_curl_fake_stdout='{"access_token":"the_new_access_token"}'
          thycotic_authenticate_curl_fake_stderr='___CURL_OUTPUT___CURL_INFORMATION_JSON___{"http_code":"200"}'
          thycotic_authenticate_curl_command() { echo "${thycotic_authenticate_curl_fake_stdout}"; echo >&2 "${thycotic_authenticate_curl_fake_stderr}"; return 0; }
        }
        Before "do_before_3"
        It "should succeed and the variable THYCOTIC_CLI_THYCOTIC_API_ACCESS_TOKEN should contain the value of the newly obtained token"
          When call ensure_thycotic_api_access_token_is_held
          The status should be success
          The variable THYCOTIC_CLI_THYCOTIC_API_ACCESS_TOKEN should equal "the_new_access_token"
        End
        Describe "when verbose output is enabled"
          do_before_4() {
            THYCOTIC_CLI_CURL_ENABLE_VERBOSE="true"
            thycotic_authenticate_curl_fake_stderr="$(echo -n -e "some\nverbose\noutput\nlines")"$'\n''___CURL_OUTPUT___CURL_INFORMATION_JSON___{"http_code":"200"}'
          }
          Before "do_before_4"
          It "should also output the curl verbose lines to stderr"
            When call ensure_thycotic_api_access_token_is_held
            The stderr should include "some"
            The stderr should include "verbose"
            The stderr should include "output"
            The stderr should include "lines"
          End
        End
      End
      Describe "when getting a new token fails"
        do_before_3() {
          get_thycotic_api_access_token() { return 1; }
        }
        Before "do_before_3"
        It "should fail and report an error"
          When call ensure_thycotic_api_access_token_is_held
          The status should be failure
          The stderr should include "Error: Failed to get an access token."
          The variable THYCOTIC_CLI_THYCOTIC_API_ACCESS_TOKEN should be undefined
        End
      End
    End
  End
End

Describe "handle_command_get_secret"
  Include "${script_under_test}"
  Include "/usr/local/bin/capture_stdout_and_stderr.sh"
  do_before_0() {
    initialize_true_and_false_strings
  }
  Before "do_before_0"
  Describe "when the --secret_id parameter is not provided"
    It "should fail and report an error"
      When call handle_command_get_secret
      The status should be failure
      The stderr should include "Error: Missing required parameter: secret_id"
      The stderr should include "Error: Failed to parse get_secret parameters."
    End
  End
  Describe "when validation of the existing access token fails"
    do_before_1() {
      THYCOTIC_CLI_THYCOTIC_API_ACCESS_TOKEN="dummy_before_token_value"
      get_user_username() { THYCOTIC_USER_USERNAME="myusername"; return 0; }
      get_user_password() { THYCOTIC_USER_PASSWORD="mypassword"; return 0; }
      validate_thycotic_api_access_token() { return 1; }
    }
    Before "do_before_1"
    It "should fail and report an error"
      When call handle_command_get_secret get_secret --secret_id=1234
      The status should be failure
      The stderr should include "Error: Failed to validate/get thycotic api access token."
    End
  End
  Describe "when getting an access token from thycotic fails"
    do_before_1() {
      THYCOTIC_CLI_THYCOTIC_API_ACCESS_TOKEN="dummy_before_token_value"
      get_user_username() { THYCOTIC_USER_USERNAME="myusername"; return 0; }
      get_user_password() { THYCOTIC_USER_PASSWORD="mypassword"; return 0; }
      # Simulate that validation of the existing access token fails.
      thycotic_get_connection_manager_settings_curl_stderr='___CURL_OUTPUT___CURL_INFORMATION_JSON___{"http_code":"123"}'
      thycotic_get_connection_manager_settings_curl_command() { echo >&2 "${thycotic_get_connection_manager_settings_curl_stderr}"; return 0; }
      # Simulate an error getting an access token from thycotic.
      thycotic_authenticate_curl_command() { echo >&2 "asdf"; return 1; }
    }
    Before "do_before_1"
    It "should fail and report an error"
      When call handle_command_get_secret get_secret --secret_id=1234
      The status should be failure
      The stderr should include "Error: Failed to obtain an access token."
      The variable THYCOTIC_CLI_THYCOTIC_API_ACCESS_TOKEN should be undefined
    End
  End
  Describe "when getting an access token from thycotic succeeds"
    do_before_1() {
      get_user_username() { THYCOTIC_USER_USERNAME="myusername"; return 0; }
      get_user_password() { THYCOTIC_USER_PASSWORD="mypassword"; return 0; }
      thycotic_authenticate_curl_fake_stdout='{"access_token":"the_new_access_token"}'
      thycotic_authenticate_curl_fake_stderr='___CURL_OUTPUT___CURL_INFORMATION_JSON___{"http_code":"200"}'
      thycotic_authenticate_curl_command() { echo "${thycotic_authenticate_curl_fake_stdout}"; echo >&2 "${thycotic_authenticate_curl_fake_stderr}"; return 0; }
    }
    Before "do_before_1"
    Describe "when getting a secret from thycotic fails"
      do_before_2() {
        thycotic_get_secret_curl_stdout='{"secret":"opensesame"}'
        thycotic_get_secret_curl_stderr='___CURL_OUTPUT___CURL_INFORMATION_JSON___{"http_code":"500","content_type":"application/json"}'
        thycotic_get_secret_curl_command() { echo "${thycotic_get_secret_curl_stdout}"; echo >&2 "${thycotic_get_secret_curl_stderr}"; return 1; }
      }
      Before "do_before_2"
      It "should fail and report an error"
        When call handle_command_get_secret get_secret --secret_id=1234
        The status should be failure
        The stderr should include "Error: Failed to get the secret."
      End
    End
    Describe "when getting a secret from thycotic succeeds"
      do_before_2() {
        thycotic_get_secret_curl_stdout='{"secret":"opensesame"}'
        thycotic_get_secret_curl_stderr='___CURL_OUTPUT___CURL_INFORMATION_JSON___{"http_code":"200","content_type":"application/json"}'
        thycotic_get_secret_curl_command() { echo "${thycotic_get_secret_curl_stdout}"; echo >&2 "${thycotic_get_secret_curl_stderr}"; return 0; }
      }
      Before "do_before_2"
      It "should succeed and the stdout should contain the content of the secret json structure response from thycotic"
        When call handle_command_get_secret get_secret --secret_id=1234
        The status should be success
        The stdout should include "secret"
        The stdout should include "opensesame"
      End
    End
  End
End

Describe "handle_command_get_secret_field_value"
  Include "${script_under_test}"
  Include "/usr/local/bin/capture_stdout_and_stderr.sh"
  do_before_0() {
    initialize_true_and_false_strings
  }
  Before "do_before_0"
  Describe "when the --secret_id parameter is not provided"
    It "should fail and report an error"
      When call handle_command_get_secret_field_value
      The status should be failure
      The stderr should include "Error: Missing required parameter: secret_id"
      The stderr should include "Error: Failed to parse get_secret_field parameters."
    End
  End
  Describe "when the --field_slug parameter is not provided"
    It "should fail and report an error"
      When call handle_command_get_secret_field_value get_secret_field_value --secret_id=1234
      The status should be failure
      The stderr should include "Error: Missing required parameter: field_slug"
      The stderr should include "Error: Failed to parse get_secret_field parameters."
    End
  End
  Describe "when getting an access token from thycotic fails"
    do_before_1() {
      THYCOTIC_CLI_THYCOTIC_API_ACCESS_TOKEN="dummy_before_token_value"
      get_user_username() { THYCOTIC_USER_USERNAME="myusername"; return 0; }
      get_user_password() { THYCOTIC_USER_PASSWORD="mypassword"; return 0; }
      # Simulate that validation of the existing access token fails.
      thycotic_get_connection_manager_settings_curl_stderr='___CURL_OUTPUT___CURL_INFORMATION_JSON___{"http_code":"123"}'
      thycotic_get_connection_manager_settings_curl_command() { echo >&2 "${thycotic_get_connection_manager_settings_curl_stderr}"; return 0; }
      # Simulate an error getting an access token from thycotic.
      thycotic_authenticate_curl_command() { echo >&2 "asdf"; return 1; }
    }
    Before "do_before_1"
    It "should fail and report an error"
      When call handle_command_get_secret_field_value get_secret_field_value --secret_id=1234 --field_slug=password
      The status should be failure
      The stderr should include "Error: Failed to obtain an access token."
      The variable THYCOTIC_CLI_THYCOTIC_API_ACCESS_TOKEN should be undefined
    End
  End
  Describe "when getting an access token from thycotic succeeds"
    do_before_1() {
      get_user_username() { THYCOTIC_USER_USERNAME="myusername"; return 0; }
      get_user_password() { THYCOTIC_USER_PASSWORD="mypassword"; return 0; }
      thycotic_authenticate_curl_fake_stdout='{"access_token":"the_new_access_token"}'
      thycotic_authenticate_curl_fake_stderr='___CURL_OUTPUT___CURL_INFORMATION_JSON___{"http_code":"200"}'
      thycotic_authenticate_curl_command() { echo "${thycotic_authenticate_curl_fake_stdout}"; echo >&2 "${thycotic_authenticate_curl_fake_stderr}"; return 0; }
    }
    Before "do_before_1"
    Describe "when getting a secret from thycotic fails"
      do_before_2() {
        get_thycotic_secret() { echo >&2 "some error getting a secret"; return 1; }
      }
      Before "do_before_2"
      It "should fail and report an error"
        When call handle_command_get_secret_field_value get_secret_field_value --secret_id=1234 --field_slug=password
        The status should be failure
        The stderr should include "Error: Failed to get the secret field value."
      End
    End
    Describe "when getting a secret from thycotic succeeds"
      do_before_2() {
        thycotic_get_secret_field_curl_stdout='{"secret":"opensesame"}'
        thycotic_get_secret_field_curl_stderr='___CURL_OUTPUT___CURL_INFORMATION_JSON___{"http_code":"200","content_type":"application/json"}'
        thycotic_get_secret_field_curl_command() { echo "${thycotic_get_secret_field_curl_stdout}"; echo >&2 "${thycotic_get_secret_field_curl_stderr}"; return 0; }
      }
      Before "do_before_2"
      It "should succeed and the stdout should contain the content of the secret json structure response from thycotic"
        When call handle_command_get_secret_field_value get_secret_field_value --secret_id=1234 --field_slug=password
        The status should be success
        The stdout should include "secret"
        The stdout should include "opensesame"
      End
    End
  End
End

Describe "handle_command_authenticate"
  Include "${script_under_test}"
  Include "/usr/local/bin/capture_stdout_and_stderr.sh"
  do_before_0() {
    initialize_true_and_false_strings
  }
  Before "do_before_0"
  Describe "when getting an access token from thycotic succeeds"
    do_before_1() {
      get_user_username() { THYCOTIC_USER_USERNAME="myusername"; return 0; }
      get_user_password() { THYCOTIC_USER_PASSWORD="mypassword"; return 0; }
      get_thycotic_api_access_token() { echo "dummy_api_access_token_value"; }
    }
    Before "do_before_1"
    It "should succeed and output an access token"
      When call handle_command_authenticate
      The status should be success
      The stdout should equal "dummy_api_access_token_value"
      The variable THYCOTIC_CLI_THYCOTIC_API_ACCESS_TOKEN should equal "dummy_api_access_token_value"
    End
  End
  Describe "when getting an access token from thycotic fails"
    do_before_1() {
      THYCOTIC_CLI_THYCOTIC_API_ACCESS_TOKEN="dummy_before_token_value"
      get_user_username() { THYCOTIC_USER_USERNAME="myusername"; return 0; }
      get_user_password() { THYCOTIC_USER_PASSWORD="mypassword"; return 0; }
      # Simulate an error getting an access token from thycotic.
      thycotic_authenticate_curl_command_fake_stderr='somecurlverboseoutput'$'\n''___CURL_OUTPUT___CURL_INFORMATION_JSON___{"errormsg":"boooooooo"}'
      thycotic_authenticate_curl_command() { echo >&2 -n -e "${thycotic_authenticate_curl_command_fake_stderr}"; return 13; }
    }
    Before "do_before_1"
    It "should fail and report an error"
      When call handle_command_authenticate
      The status should be failure
      The stderr should include "Error: Failed to obtain an access token."
      The variable THYCOTIC_CLI_THYCOTIC_API_ACCESS_TOKEN should be undefined
    End
  End
End

Describe "get_thycotic_secret"
  Include "${script_under_test}"
  Include "/usr/local/bin/capture_stdout_and_stderr.sh"
  do_before_0() {
    initialize_true_and_false_strings
    thycotic_get_secret_curl_command_fake_rc="0"
    thycotic_get_secret_curl_command_fake_stdout='{"secret":"opensesame"}'
    thycotic_get_secret_curl_command_fake_stderr='___CURL_OUTPUT___CURL_INFORMATION_JSON___{"http_code":"200","content_type":"application/json"}'
    thycotic_get_secret_curl_command() { echo "${thycotic_get_secret_curl_command_fake_stdout}"; echo >&2 "${thycotic_get_secret_curl_command_fake_stderr}"; return "${thycotic_get_secret_curl_command_fake_rc}"; }
  }
  Before "do_before_0"
  Describe "when the curl call stderr is not json"
    do_before_1() {
      thycotic_get_secret_curl_command_fake_stderr="thisisnotjson"
    }
    Before "do_before_1"
    It "should fail and report an error"
      When call get_thycotic_secret
      The status should be failure
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Error: Failed to get the secret."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Message UUID: 5832ab7a-7df8-44ef-925e-528fded45bbb"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Failed to get the curl_information_json value from the curl stderr."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The thycotic_get_secret stderr:"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "curl_verbose_output_base64"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "dGhpc2lzbm90anNvbg==" # The base64 encoding of thisisnotjson
    End
  End
  Describe "when the curl call stderr is json but does not include the curl_information_json element"
    do_before_1() {
      # This can't be simulated by mocking thycotic_get_secret_curl_command(), but only my mocking thycotic_get_secret().
      thycotic_get_secret() { echo -n "blah"; echo >&2 '{"foo":"bar"}'; return 0; }
    }
    Before "do_before_1"
    It "should fail and report an error"
      When call get_thycotic_secret
      The status should be failure
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Error: Failed to get the secret."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Message UUID: 5832ab7a-7df8-44ef-925e-528fded45bbb"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Failed to get the curl_information_json value from the curl stderr."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The thycotic_get_secret stderr:"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "foo"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "bar"
    End
  End
  Describe "when the curl call stderr is json but does not include the curl_verbose_output_base64 element"
    do_before_1() {
      # This can't be simulated by mocking thycotic_get_secret_curl_command(), but only my mocking thycotic_get_secret().
      thycotic_get_secret() { echo -n "blah"; echo >&2 '{"curl_information_json":"hello"}'; return 0; }
    }
    Before "do_before_1"
    It "should fail and report an error"
      When call get_thycotic_secret
      The status should be failure
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Error: Failed to get the secret."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Message UUID: 77f637de-b006-48d9-8b2d-f153f88e85e5"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Failed to get the curl_verbose_output_base64 value from the curl stderr."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The thycotic_get_secret stderr:"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "curl_information_json"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "hello"
    End
  End
  Describe "when thycotic get secret call fails"
    do_before_1() {
      thycotic_get_secret_curl_command_fake_rc="101"
      thycotic_get_secret_curl_command_fake_stderr='___CURL_OUTPUT___CURL_INFORMATION_JSON___{"errormsg":"dummy_error_message_from_curl"}'
    }
    Before "do_before_1"
    It "should fail and report an error"
      When call get_thycotic_secret
      The status should be failure
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Error: Failed to get the secret."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Message UUID: 7b8f8276-ee2f-4040-a8ba-c9fe657419f9"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The curl command to get the secret from Thycotic failed with return code: 101"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The curl error message: dummy_error_message_from_curl"
    End
    Describe "when the curl_information_json (curl stderr) does not contain an errormsg element"
      do_before_2() {
        thycotic_get_secret_curl_command_fake_stderr='___CURL_OUTPUT___CURL_INFORMATION_JSON___{"foo":"bar"}'
      }
      Before "do_before_2"
      It "should fail and report an error"
        When call get_thycotic_secret
        The status should be failure
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Error: Failed to get the secret."
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Message UUID: 7b8f8276-ee2f-4040-a8ba-c9fe657419f9"
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The curl command to get the secret from Thycotic failed with return code: 101"
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Failed to get the error message (errormsg element) from the curl information JSON."
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The curl command error text is:"
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "foo"
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "bar"
      End
    End
  End
  Describe "when the curl_information_json (curl stderr) is json but it does not contain a http_code element"
    do_before_2() {
      thycotic_get_secret_curl_command_fake_stderr='___CURL_OUTPUT___CURL_INFORMATION_JSON___{"foo":"bar"}'
    }
    Before "do_before_2"
    It "should fail and report an error"
      When call get_thycotic_secret
      The status should be failure
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Error: Failed to get the secret."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Message UUID: ba36113f-88a6-4564-a169-e83938b16b12"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Failed to get the HTTP status code (http_code element) from the curl information JSON."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The curl information JSON is:"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "foo"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "bar"
    End
  End
  Describe "when the http_code value is not 200"
    do_before_2() {
      thycotic_get_secret_curl_command_fake_stdout='{"error":"the curl get secret error message"}'
      thycotic_get_secret_curl_command_fake_stderr='___CURL_OUTPUT___CURL_INFORMATION_JSON___{"http_code":"501","content_type":"application/json"}'
    }
    Before "do_before_2"
    It "should fail and report an error"
      When call get_thycotic_secret
      The status should be failure
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Error: Failed to get the secret."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Message UUID: f4cec091-8a20-43ec-865f-cd543ec335b3"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The HTTP status code for the 'get secret' call to Thycotic was: 501  (expected 200)."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Thycotic get secret error message: the curl get secret error message"
    End
    Describe "when the stdout does not contain the error element"
      do_before_3() {
        thycotic_get_secret_curl_command_fake_stdout='{"foo":"bar"}'
      }
      Before "do_before_3"
      It "should fail and report an error"
        When call get_thycotic_secret
        The status should be failure
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Error: Failed to get the secret."
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Message UUID: f4cec091-8a20-43ec-865f-cd543ec335b3"
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The HTTP status code for the 'get secret' call to Thycotic was: 501  (expected 200)."
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Failed to get the error message (error element) from the Thycotic get secret response JSON."
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Thycotic get secret response JSON:"
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "foo"
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "bar"
      End
    End
  End
  Describe "when the curl_information_json does not contain the content_type element"
    do_before_2() {
      thycotic_get_secret_curl_command_fake_stderr='___CURL_OUTPUT___CURL_INFORMATION_JSON___{"http_code":"200"}'
    }
    Before "do_before_2"
    It "should fail and report an error"
      When call get_thycotic_secret
      The status should be failure
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Error: Failed to get the secret."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Message UUID: 7bd848d3-46ef-4499-bd4e-e4e783e2f542"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Failed to get the Content-Type value (content_type element) from the curl information JSON."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The curl information JSON is:"
    End
  End
  Describe "when the content_type element value is application/json"
    do_before_2() {
      thycotic_get_secret_curl_command_fake_stderr='___CURL_OUTPUT___CURL_INFORMATION_JSON___{"http_code":"200","content_type":"application/json"}'
    }
    Before "do_before_2"
    Describe "when the get secret field response is not json"
      do_before_3() {
        thycotic_get_secret_curl_command_fake_stdout='thisisnotjson' # not valid json - the string is not in double quotes
      }
      Before "do_before_3"
      It "should fail and report an error"
        When call get_thycotic_secret
        The status should be failure
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Error: Failed to get the secret."
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Message UUID: f9df7043-8a3c-47a3-b6b8-aa629a0fdcdc"
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Failed to parse the response as JSON when the content type was application/json"
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Thycotic get secret response JSON:"
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "thisisnotjson"
      End
    End
    Describe "when the get secret field response is json"
      do_before_3() {
        thycotic_get_secret_curl_command_fake_stdout='{"secret":"opensesame"}'
      }
      Before "do_before_3"
      It "should succeed and the THYCOTIC_CLI_SECRET_JSON variable should equal the secret json"
        When call get_thycotic_secret
        The status should be success
        The stdout should include "secret"
        The stdout should include "opensesame"
        # TODO The assert here could be more precise, assert that the stdout is valid json, contains a "secret" element, and that the value of the secret element is "opensesame"
      End
    End
  End
  Describe "when the content_type is not an expected type"
    do_before_2() {
      thycotic_get_secret_curl_command_fake_stderr='___CURL_OUTPUT___CURL_INFORMATION_JSON___{"http_code":"200","content_type":"typeblah"}'
    }
    Before "do_before_2"
    It "should fail and report an error"
      When call get_thycotic_secret
      The status should be failure
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Error: Failed to get the secret."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Message UUID: 30ebc3eb-ab9e-4200-a4f4-b378ae093249"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Unexpected content type: typeblah"
    End
  End
End

Describe "get_thycotic_secret_field_value"
  Include "${script_under_test}"
  Include "/usr/local/bin/capture_stdout_and_stderr.sh"
  do_before_0() {
    initialize_true_and_false_strings
    thycotic_get_secret_field_curl_command_fake_rc="0"
    thycotic_get_secret_field_curl_command_fake_stdout='thesecretfieldvalue'
    thycotic_get_secret_field_curl_command_fake_stderr='___CURL_OUTPUT___CURL_INFORMATION_JSON___{"http_code":"200","content_type":"application/json"}'
    thycotic_get_secret_field_curl_command() { echo "${thycotic_get_secret_field_curl_command_fake_stdout}"; echo >&2 "${thycotic_get_secret_field_curl_command_fake_stderr}"; return "${thycotic_get_secret_field_curl_command_fake_rc}"; }
  }
  Before "do_before_0"
  Describe "when the curl call stderr is not json"
    do_before_1() {
      thycotic_get_secret_field_curl_command_fake_stderr="thisisnotjson"
    }
    Before "do_before_1"
    It "should fail and report an error"
      When call get_thycotic_secret_field_value
      The status should be failure
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Error: Failed to get the secret field value."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Message UUID: f21774c1-fe3b-4c17-89dc-d1b119fb9566"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Failed to get the curl_information_json value from the curl stderr."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The thycotic_get_secret_field stderr:"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "curl_verbose_output_base64"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "dGhpc2lzbm90anNvbg==" # The base64 encoding of thisisnotjson
    End
  End
  Describe "when the curl call stderr is json but does not include the curl_information_json element"
    do_before_1() {
      thycotic_get_secret_field() { echo -n "blah"; echo >&2 '{"foo":"bar"}'; return 0; }
    }
    Before "do_before_1"
    It "should fail and report an error"
      When call get_thycotic_secret_field_value
      The status should be failure
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Error: Failed to get the secret field value."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Message UUID: f21774c1-fe3b-4c17-89dc-d1b119fb9566"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Failed to get the curl_information_json value from the curl stderr."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The thycotic_get_secret_field stderr:"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "foo"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "bar"
    End
  End
  Describe "when the curl call stderr is json but does not include the curl_verbose_output_base64 element"
    do_before_1() {
      thycotic_get_secret_field() { echo -n "blah"; echo >&2 '{"curl_information_json":"hello"}'; return 0; }
    }
    Before "do_before_1"
    It "should fail and report an error"
      When call get_thycotic_secret_field_value
      The status should be failure
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Error: Failed to get the secret field value."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Message UUID: 10ffc22f-e521-4e7b-9e6e-8344316647c2"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Failed to get the curl_verbose_output_base64 value from the curl stderr."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The thycotic_get_secret_field stderr:"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "curl_information_json"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "hello"
    End
  End
  Describe "when thycotic get secret field call fails"
    do_before_1() {
      thycotic_get_secret_field_curl_command_fake_rc="101"
      thycotic_get_secret_field_curl_command_fake_stderr='___CURL_OUTPUT___CURL_INFORMATION_JSON___{"errormsg":"dummy_error_message_from_curl"}'
    }
    Before "do_before_1"
    It "should fail and report an error"
      When call get_thycotic_secret_field_value
      The status should be failure
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Error: Failed to get the secret field value."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Message UUID: 2b2f7369-0e85-49f1-b8bc-b819fcb8bc66"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The curl command to get the secret field from Thycotic failed with return code: 101"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The curl error message: dummy_error_message_from_curl"
    End
    Describe "when the curl_information_json (curl stderr) does not contain an errormsg element"
      do_before_2() {
        thycotic_get_secret_field_curl_command_fake_stderr='___CURL_OUTPUT___CURL_INFORMATION_JSON___{"foo":"bar"}'
      }
      Before "do_before_2"
      It "should fail and report an error"
        When call get_thycotic_secret_field_value
        The status should be failure
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Error: Failed to get the secret field value."
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Message UUID: 2b2f7369-0e85-49f1-b8bc-b819fcb8bc66"
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The curl command to get the secret field from Thycotic failed with return code: 101"
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Failed to get the error message (errormsg element) from the curl information JSON."
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The curl command error text is:"
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "foo"
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "bar"
      End
    End
  End
  Describe "when the curl_information_json (curl stderr) is json but it does not contain a http_code element"
    do_before_2() {
      thycotic_get_secret_field_curl_command_fake_stderr='___CURL_OUTPUT___CURL_INFORMATION_JSON___{"foo":"bar"}'
    }
    Before "do_before_2"
    It "should fail and report an error"
      When call get_thycotic_secret_field_value
      The status should be failure
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Error: Failed to get the secret field value."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Message UUID: 7ffd878a-04c9-473a-ae46-e049c8af5d5b"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Failed to get the HTTP status code (http_code element) from the curl information JSON."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The curl information JSON is:"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "foo"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "bar"
    End
  End
  Describe "when the http_code value is not 200"
    do_before_2() {
      thycotic_get_secret_field_curl_command_fake_stdout='{"error":"the curl get secret field error message"}'
      thycotic_get_secret_field_curl_command_fake_stderr='___CURL_OUTPUT___CURL_INFORMATION_JSON___{"http_code":"501","content_type":"application/json"}'
    }
    Before "do_before_2"
    It "should fail and report an error"
      When call get_thycotic_secret_field_value
      The status should be failure
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Error: Failed to get the secret field value."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Message UUID: 1d97aa42-732b-4880-84f6-b2137b48cfa9"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The HTTP status code for the 'get secret field' call to Thycotic was: 501  (expected 200)."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Thycotic get secret field error message: the curl get secret field error message"
    End
    Describe "when the stdout does not contain the error element"
      do_before_3() {
        thycotic_get_secret_field_curl_command_fake_stdout='{"foo":"bar"}'
      }
      Before "do_before_3"
      It "should fail and report an error"
        When call get_thycotic_secret_field_value
        The status should be failure
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Error: Failed to get the secret field value."
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Message UUID: 1d97aa42-732b-4880-84f6-b2137b48cfa9"
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The HTTP status code for the 'get secret field' call to Thycotic was: 501  (expected 200)."
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Failed to get the error message (error element) from the Thycotic get secret field response JSON."
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Thycotic get secret field response:"
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "foo"
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "bar"
      End
    End
  End
  Describe "when the curl_information_json does not contain the content_type element"
    do_before_2() {
      thycotic_get_secret_field_curl_command_fake_stderr='___CURL_OUTPUT___CURL_INFORMATION_JSON___{"http_code":"200"}'
    }
    Before "do_before_2"
    It "should fail and report an error"
      When call get_thycotic_secret_field_value
      The status should be failure
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Error: Failed to get the secret field value."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Message UUID: b82d5534-690f-41ee-83e8-94390e751381"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Failed to get the Content-Type value (content_type element) from the curl information JSON."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The curl information JSON is:"
    End
  End
  Describe "when the content_type is application/octet-stream"
    do_before_2() {
      thycotic_get_secret_field_curl_command_fake_stdout='someoctetstream'
      thycotic_get_secret_field_curl_command_fake_stderr='___CURL_OUTPUT___CURL_INFORMATION_JSON___{"http_code":"200","content_type":"application/octet-stream"}'
    }
    Before "do_before_2"
    It "should succeed and the stdout should equal of the secret field value"
      When call get_thycotic_secret_field_value
      The status should be success
      The stdout should equal "someoctetstream"
    End
  End
  Describe "when the content_type element value is application/json"
    do_before_2() {
      thycotic_get_secret_field_curl_command_fake_stderr='___CURL_OUTPUT___CURL_INFORMATION_JSON___{"http_code":"200","content_type":"application/json"}'
    }
    Before "do_before_2"
    Describe "when the get secret field response is not json"
      do_before_3() {
        thycotic_get_secret_field_curl_command_fake_stdout='thisisnotjson' # not valid json - the string is not in double quotes
      }
      Before "do_before_3"
      It "should fail and report an error"
        When call get_thycotic_secret_field_value
        The status should be failure
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Error: Failed to get the secret field value."
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Message UUID: a6893c48-e73c-4930-9722-f94a09c45f61"
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Failed to parse the response as JSON when the content type was application/json"
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Thycotic get secret field response:"
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "thisisnotjson"
      End
    End
    Describe "when the get secret field response is json"
      do_before_3() {
        thycotic_get_secret_field_curl_command_fake_stdout='"myverysecretpassword"' # valid json - string in double quotes
      }
      Before "do_before_3"
      It "should succeed and the stdout should equal the secret field value"
        When call get_thycotic_secret_field_value
        The status should be success
        The stdout should equal "myverysecretpassword"
      End
    End
  End
  Describe "when the content_type is not an expected type"
    do_before_2() {
      thycotic_get_secret_field_curl_command_fake_stderr='___CURL_OUTPUT___CURL_INFORMATION_JSON___{"http_code":"200","content_type":"typeblah"}'
    }
    Before "do_before_2"
    It "should fail and report an error"
      When call get_thycotic_secret_field_value
      The status should be failure
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Error: Failed to get the secret field value."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Message UUID: 9dfb9696-3065-4a56-aea8-cf1f883fd30d"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Unexpected content type: typeblah"
    End
  End
End

Describe "get_user_username"
  Include "${script_under_test}"
  Include "/usr/local/bin/capture_stdout_and_stderr.sh"
  Describe "when the GET_USERNAME_COMMAND fails"
    do_before() {
      THYCOTIC_CLI_GET_USERNAME_COMMAND="false"
    }
    Before "do_before"
    Data
      #|username_from_prompt
    End
    Describe "when THYCOTIC_CLI_USERNAME is defined"
      do_before2() {
        THYCOTIC_CLI_USERNAME="dummyusername"
        USER="dummyUSERvalue"
      }
      Before "do_before2"
      It "should output error message and prompt for username"
        When call get_user_username
        The stderr should include "Warning: The command contained in THYCOTIC_CLI_GET_USERNAME_COMMAND failed and won't be used."
        The stderr should include "Thycotic - Please enter your Username [dummyusername]:"
        The status should equal 0
        The variable THYCOTIC_USER_USERNAME should equal "username_from_prompt"
      End
    End
    Describe "when THYCOTIC_CLI_USERNAME is not defined"
      do_before2() {
        unset THYCOTIC_CLI_USERNAME
        USER="dummyUSERvalue"
      }
      Before "do_before2"
      It "should output error message and prompt for username"
        When call get_user_username
        The stderr should include "Warning: The command contained in THYCOTIC_CLI_GET_USERNAME_COMMAND failed and won't be used."
        The stderr should include "Thycotic - Please enter your Username [dummyUSERvalue]:"
        The status should equal 0
        The variable THYCOTIC_USER_USERNAME should equal "username_from_prompt"
      End
    End
    Describe "when THYCOTIC_CLI_USERNAME is not defined and USER is not defined"
      do_before2() {
        unset THYCOTIC_CLI_USERNAME
        unset USER
      }
      Before "do_before2"
      It "should output error message and prompt for username"
        When call get_user_username
        The stderr should include "Warning: The command contained in THYCOTIC_CLI_GET_USERNAME_COMMAND failed and won't be used."
        The stderr should include "Thycotic - Please enter your Username []:"
        The status should equal 0
        The variable THYCOTIC_USER_USERNAME should equal "username_from_prompt"
      End
    End
  End
  Describe "when the GET_USERNAME_COMMAND succeeds"
    do_before() {
      THYCOTIC_CLI_GET_USERNAME_COMMAND="echo username_from_command"
    }
    Before "do_before"
    It "should use the value provide by the get user command"
      When call get_user_username
      The status should equal 0
      The variable THYCOTIC_USER_USERNAME should equal "username_from_command"
    End
  End
End

Describe "get_user_password"
  Include "${script_under_test}"
  Include "/usr/local/bin/capture_stdout_and_stderr.sh"
  Describe "when the GET_PASSWORD_COMMAND fails"
    do_before() {
      THYCOTIC_USER_USERNAME="theusername"
      THYCOTIC_CLI_GET_PASSWORD_COMMAND="false"
    }
    Before "do_before"
    Data
      #|password_from_prompt
    End
    It "should output error message and prompt for password"
      When call get_user_password
      The stderr should include "Warning: The command contained in THYCOTIC_CLI_GET_PASSWORD_COMMAND failed and won't be used."
      The stderr should include "Thycotic - Please enter the Password for user theusername:"
      The status should equal 0
      The variable THYCOTIC_USER_PASSWORD should equal "password_from_prompt"
    End
  End
  Describe "when the GET_PASSWORD_COMMAND succeeds"
    do_before() {
      THYCOTIC_CLI_GET_PASSWORD_COMMAND="echo password_from_command"
    }
    Before "do_before"
    It "should use the value provide by the get password command"
      When call get_user_password
      The status should equal 0
      The variable THYCOTIC_USER_PASSWORD should equal "password_from_command"
    End
  End
End

Describe "get_http_code_from_curl_information_json"
  Include "${script_under_test}"
  Include "/usr/local/bin/capture_stdout_and_stderr.sh"
  do_before() {
    not_json="this is not json"
    json_but_missing_http_code_element="{\"elementname1\":\"elementvalue1\",\"elementname2\":\"elementvalue2\"}"
    json_but_empty_http_code_element="{\"elementname1\":\"elementvalue1\",\"http_code\":\"\"}"
    json_with_http_code_element_200="{\"elementname1\":\"elementvalue1\",\"http_code\":\"200\"}"
  }
  Before "do_before"
  It "should exit with status 1 when parameter 1 is not provided"
    When call get_http_code_from_curl_information_json
    The status should equal 1
    The stderr should include "Error in get_http_code_from_curl_information_json - parameter 1 does not have a value"
  End
  It "should exit with status 3 when the http_code element could not be obtained from the json"
    When call get_http_code_from_curl_information_json not_json
    The status should equal 3
    The stderr should include "Error in get_http_code_from_curl_information_json - failed to get .http_code from curl information json"
    The stderr should include "get_json_element_value return code:"
    The stderr should include "get_json_element_value error message:"
    The stderr should include "The curl information json provided (named not_json) was:"
    The stderr should include "this is not json"
  End
  It "should exit with status 3 when the http_code element is not present in the json"
    When call get_http_code_from_curl_information_json json_but_missing_http_code_element
    The status should equal 3
    The stderr should include "Error in get_http_code_from_curl_information_json - failed to get .http_code from curl information json"
    The stderr should include "get_json_element_value return code:"
    The stderr should include "get_json_element_value error message:"
    The stderr should include "The curl information json provided (named json_but_missing_http_code_element) was:"
    The stderr should include "{\"elementname1\":\"elementvalue1\",\"elementname2\":\"elementvalue2\"}"
  End
  It "should exit with status 4 when the http_code element is empty"
    When call get_http_code_from_curl_information_json json_but_empty_http_code_element
    The status should equal 4
    The stderr should include "Error in get_http_code_from_curl_information_json - the http_code from the curl information json was empty"
    The stderr should include "The curl information json provided (named json_but_empty_http_code_element) was:"
    The stderr should include "{\"elementname1\":\"elementvalue1\",\"http_code\":\"\"}"
  End
  It "should output the http code to stdout and exit with status 0 when the http_code element is present and non-empty"
    When call get_http_code_from_curl_information_json json_with_http_code_element_200
    The status should equal 0
    The stdout should equal "200"
  End
End

Describe "get_json_element_value"
  Include "${script_under_test}"
  Include "/usr/local/bin/capture_stdout_and_stderr.sh"
  do_before() {
    json_with_element_foo_being_null="{\"foo\":null}"
    json_with_element_foo="{\"foo\":\"bar\"}"
    not_json="this is not json"
    json_but_missing_http_code_element="{\"elementname1\":\"elementvalue1\",\"elementname2\":\"elementvalue2\"}"
    json_but_empty_http_code_element="{\"elementname1\":\"elementvalue1\",\"http_code\":\"\"}"
    json_with_http_code_element_200="{\"elementname1\":\"elementvalue1\",\"http_code\":\"200\"}"
  }
  Before "do_before"
  It "should exit with status 1 if parameter 1 does not have a value"
    When call get_json_element_value
    The status should equal 1
    The stderr should equal "Error in get_json_element_value - parameter 1 does not have a value"
  End
  It "should exit with status 1 if parameter 2 does not have a value"
    When call get_json_element_value blah
    The status should equal 2
    The stderr should equal "Error in get_json_element_value - parameter 2 does not have a value"
  End
  It "should exit with status 3 if the jq command to determine if the element exists fails"
    When call get_json_element_value blah asdf
    The status should equal 3
    The stderr should include "jq: error:"
  End
  It "should exit with status 4 if the element does not exist"
    When call get_json_element_value .blah json_with_element_foo
    The status should equal 4
    The stderr should include "Element .blah does not exist or is null"
  End
  It "should exit with status 4 if the element does not exist or is null"
    When call get_json_element_value .foo json_with_element_foo_being_null
    The status should equal 4
    The stderr should include "Element .foo does not exist or is null"
  End
  Describe "when the second jq command used fails"
    do_before() {
      # Redefine the 'jq' command so that the second call to it (made in the get_json_element_value
      # function) fails, so that the error condition of
      # 'if the jq command to get the value of the element fails' can be tested
      # (the first call to jq can simply return status 0).
      echo -n "" > /tmp/jq_call_counter;
      jq() { echo "called - jq ${*}" >> /tmp/jq_call_counter; jq_call_count="$(cat /tmp/jq_call_counter | wc -l)"; echo >&2 "jq_call_count is ${jq_call_count}"; if [ "${jq_call_count}" = "1" ]; then return 0; else return 1; fi; }
    }
    Before "do_before"
    It "should exit with status 5 if the jq command to get the value of the element fails"
      When call get_json_element_value .foo json_with_element_foo
      The status should equal 5
      The stderr should include "An error occurred getting element .foo from the json."
    End
  End
  It "should output the value of the element if the element exists and has a value"
    When call get_json_element_value .foo json_with_element_foo
    The status should equal 0
    The stdout should equal "bar"
  End
End

Describe "get_thycotic_api_access_token"
  Include "${script_under_test}"
  Include "/usr/local/bin/capture_stdout_and_stderr.sh"
  do_before_0() {
    initialize_true_and_false_strings
  }
  Before "do_before_0"
  Describe "when the thycotic_authenticate command stderr is not json"
    do_before3() {
      thycotic_authenticate_fake_stderr='notjson'
      thycotic_authenticate() { echo >&2 "${thycotic_authenticate_fake_stderr}"; return 9; }
    }
    Before "do_before3"
    It "should exit with status 15 and report an error"
      When call get_thycotic_api_access_token
      The status should equal 15
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Error: Failed to obtain an access token."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Message UUID: 3b7fb59e-fae0-4a77-848f-d511be3671f3"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Failed to get the curl_information_json value from the curl stderr."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The thycotic_authenticate stderr:"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "notjson"
    End
  End
  Describe "when the thycotic_authenticate command stderr does not contain a curl_information_json element"
    do_before3() {
      thycotic_authenticate_fake_stderr='{"foo":"bar"}'
      thycotic_authenticate() { echo >&2 "${thycotic_authenticate_fake_stderr}"; return 0; }
    }
    Before "do_before3"
    It "should exit with status 15 and report an error"
      When call get_thycotic_api_access_token
      The status should equal 15
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Error: Failed to obtain an access token."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Message UUID: 3b7fb59e-fae0-4a77-848f-d511be3671f3"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Failed to get the curl_information_json value from the curl stderr."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The thycotic_authenticate stderr:"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "foo"
    End
  End
  Describe "when the thycotic_authenticate command stderr does not contain a curl_verbose_output_base64 element"
    do_before3() {
      thycotic_authenticate_fake_stderr='{"curl_information_json":"somecurlinformationjson"}'
      thycotic_authenticate() { echo >&2 "${thycotic_authenticate_fake_stderr}"; return 0; }
    }
    Before "do_before3"
    It "should exit with status 16 and report an error"
      When call get_thycotic_api_access_token
      The status should equal 16
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Error: Failed to obtain an access token."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Message UUID: ea7cc439-17f8-4ef2-8682-24140af9bd60"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Failed to get the curl_verbose_output_base64 value from the curl stderr."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The thycotic_authenticate stderr:"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "somecurlinformationjson"
    End
  End
  Describe "when the thycotic_authenticate_curl_command fails"
    do_before3() {
      thycotic_authenticate_curl_fake_stderr='___CURL_OUTPUT___CURL_INFORMATION_JSON___{"errormsg":"dummy_error_message_from_curl"}'
      thycotic_authenticate_curl_command() { echo >&2 "${thycotic_authenticate_curl_fake_stderr}"; return 9; }
    }
    Before "do_before3"
    It "should exit with status 17"
      When call get_thycotic_api_access_token
      The status should equal 17
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Error: Failed to obtain an access token."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Message UUID: 64dd1032-b73f-441f-bfa0-f6c5fadece15"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The curl command to authenticate to Thycotic failed with return code: 9"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The curl error message:"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "dummy_error_message_from_curl"
    End
    Describe "when the thycotic_authenticate_curl_command stderr does not contain an errormsg element"
      do_before4() {
        thycotic_authenticate_curl_fake_stderr='___CURL_OUTPUT___CURL_INFORMATION_JSON___{"foo":"bar"}'
      }
      Before "do_before4"
      It "should exit with status 17"
        When call get_thycotic_api_access_token
        The status should equal 17
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Error: Failed to obtain an access token."
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Message UUID: 64dd1032-b73f-441f-bfa0-f6c5fadece15"
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The curl command to authenticate to Thycotic failed with return code: 9"
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Failed to get the error message (errormsg element) from the curl information JSON."
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The curl command error output is:"
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "foo"
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "bar"
      End
    End
  End
  Describe "when the thycotic_authenticate_curl_command succeeds"
    do_before_4() {
      thycotic_authenticate_curl_fake_stdout='dummy_stdout'
      thycotic_authenticate_curl_fake_http_code="567"
      thycotic_authenticate_curl_fake_stderr='___CURL_OUTPUT___CURL_INFORMATION_JSON___{"http_code":'"${thycotic_authenticate_curl_fake_http_code}"'}'
      thycotic_authenticate_curl_command() { echo "${thycotic_authenticate_curl_fake_stdout}"; echo >&2 "${thycotic_authenticate_curl_fake_stderr}"; return 0; }
    }
    Before "do_before_4"
    Describe "when the curl_information_json (stderr from the thycotic_authenticate_curl_command function) is not valid json"
      do_before_5() {
        thycotic_authenticate_curl_fake_stderr='___CURL_OUTPUT___CURL_INFORMATION_JSON___"this_is_invalid_curl_information_json"'
      }
      Before "do_before_5"
      It "should exit with status 18 and report an error"
        When call get_thycotic_api_access_token
        The status should equal 18
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Error: Failed to obtain an access token."
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Message UUID: 6501f01c-1007-44f9-851e-1a803aab2b09"
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Failed to get the HTTP status code (http_code element) from the curl information JSON."
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The curl information JSON is:"
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "this_is_invalid_curl_information_json"
      End
    End
    Describe "when the curl_information_json (stderr from the thycotic_authenticate_curl_command function) is valid json but does not contain a http_code element"
      do_before_5() {
        thycotic_authenticate_curl_fake_stderr='___CURL_OUTPUT___CURL_INFORMATION_JSON___{"foo":"bar"}'
      }
      Before "do_before_5"
      It "should exit with status 18 and report an error"
        When call get_thycotic_api_access_token
        The status should equal 18
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Error: Failed to obtain an access token."
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Message UUID: 6501f01c-1007-44f9-851e-1a803aab2b09"
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Failed to get the HTTP status code (http_code element) from the curl information JSON."
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The curl information JSON is:"
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "foo"
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "bar"
      End
    End
    Describe "when the curl_information_json (stderr from the thycotic_authenticate_curl_command function) is valid json and contains a http_code element that is not 200"
      do_before_5() {
        thycotic_authenticate_curl_fake_http_code="357"
        thycotic_authenticate_curl_fake_stderr='___CURL_OUTPUT___CURL_INFORMATION_JSON___{"http_code":'"${thycotic_authenticate_curl_fake_http_code}"'}'
      }
      Before "do_before_5"
      It "should exit with status 19 and report an error"
        When call get_thycotic_api_access_token
        The status should equal 19
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Error: Failed to obtain an access token."
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Message UUID: 74a75572-692f-4e08-99eb-680763aadec0"
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The HTTP status code for the authentication to Thycotic was: 357  (expected 200)."
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Thycotic authenticate response JSON:"
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "dummy_stdout"
      End
      Describe "when the Thycotic authenticate response JSON contains an error element"
        do_before_6() {
          thycotic_authenticate_curl_fake_stdout='{"error":"thycotic_authenticate_error_message"}'
        }
        Before "do_before_6"
        It "should exit with status 19 and report an error"
          When call get_thycotic_api_access_token
          The status should equal 19
          The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Error: Failed to obtain an access token."
          The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Message UUID: 74a75572-692f-4e08-99eb-680763aadec0"
          The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The HTTP status code for the authentication to Thycotic was: 357  (expected 200)."
          The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Thycotic authenticate error message:"
          The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "thycotic_authenticate_error_message"
        End
      End
    End
    Describe "when the curl_information_json (stderr from the thycotic_authenticate_curl_command function) is valid json and contains a http_code element that is 200"
      do_before_5() {
        thycotic_authenticate_curl_fake_http_code="200"
        thycotic_authenticate_curl_fake_stderr='___CURL_OUTPUT___CURL_INFORMATION_JSON___{"http_code":'"${thycotic_authenticate_curl_fake_http_code}"'}'
      }
      Before "do_before_5"
      Describe "when the Thycotic authenticate response is not valid JSON"
        do_before_6() {
          thycotic_authenticate_curl_fake_stdout='not_valid_json'
        }
        Before "do_before_6"
        It "should exit with status 20 and report an error"
          When call get_thycotic_api_access_token
          The status should equal 20
          The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Error: Failed to obtain an access token."
          The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Message UUID: 66159660-5153-4a5c-b176-c50be01f68e6"
          The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Failed to get the Access Token (access_token element) from the Thycotic authenticate response JSON."
          The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Thycotic authenticate response JSON:"
          The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "not_valid_json"
        End
      End
      Describe "when the Thycotic authenticate response is valid JSON but does not contain an access_token element"
        do_before_6() {
          thycotic_authenticate_curl_fake_stdout='{"foo":"bar"}'
        }
        Before "do_before_6"
        It "should exit with status 20 and report an error"
          When call get_thycotic_api_access_token
          The status should equal 20
          The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Error: Failed to obtain an access token."
          The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Message UUID: 66159660-5153-4a5c-b176-c50be01f68e6"
          The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Failed to get the Access Token (access_token element) from the Thycotic authenticate response JSON."
          The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Thycotic authenticate response JSON:"
          The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "foo"
          The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "bar"
        End
      End
      Describe "when the Thycotic authenticate response is valid JSON and contains an access_token element"
        do_before_6() {
          thycotic_authenticate_curl_fake_stdout='{"access_token":"fakevalidaccesstoken"}'
        }
        Before "do_before_6"
        It "should exit with status 0 and the THYCOTIC_CLI_THYCOTIC_API_ACCESS_TOKEN variable should be the value of the access_token element"
          When call get_thycotic_api_access_token
          The status should equal 0
          The stdout should equal "fakevalidaccesstoken"
        End
        Describe "when verbose output is enabled"
          do_before_7() {
            THYCOTIC_CLI_CURL_ENABLE_VERBOSE="true"
            thycotic_authenticate_curl_fake_stderr="$(echo -n -e "some\nverbose\noutput\nlines")"$'\n''___CURL_OUTPUT___CURL_INFORMATION_JSON___{"http_code":'"${thycotic_authenticate_curl_fake_http_code}"'}'
          }
          Before "do_before_7"
          It "should also respond with the curl_verbose_output_base64 value"
            When call get_thycotic_api_access_token
            The stdout should equal "fakevalidaccesstoken"
            The stderr should include "c29tZQp2ZXJib3NlCm91dHB1dApsaW5lcw==" # this is the base64 encoded value of the example curl verbose output used above. That is: echo -n -e "some\nverbose\noutput\nlines" | base64
          End
        End
      End
    End
  End
End

Describe "validate_thycotic_api_access_token"
  Include "${script_under_test}"
  Include "/usr/local/bin/capture_stdout_and_stderr.sh"
  do_before_0() {
    initialize_true_and_false_strings
    thycotic_get_connection_manager_settings_curl_command_fake_rc="0"
    thycotic_get_connection_manager_settings_curl_command_fake_stdout='dummy'
    thycotic_get_connection_manager_settings_curl_command_fake_stderr='___CURL_OUTPUT___CURL_INFORMATION_JSON___{"http_code":"200"}'
    thycotic_get_connection_manager_settings_curl_command() { echo "${thycotic_get_connection_manager_settings_curl_command_fake_stdout}"; echo >&2 "${thycotic_get_connection_manager_settings_curl_command_fake_stderr}"; return "${thycotic_get_connection_manager_settings_curl_command_fake_rc}"; }
  }
  Before "do_before_0"
  Describe "when the curl call stderr is not json"
    do_before_1() {
      thycotic_get_connection_manager_settings_curl_command_fake_stderr="thisisnotjson"
    }
    Before "do_before_1"
    It "should fail and report an error"
      When call validate_thycotic_api_access_token
      The status should be failure
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Error: Failed to check the validity of the Thycotic API Access Token."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Message UUID: cd6f780f-8fd6-4f57-b62c-9d7f04d6e01a"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Failed to get the curl_information_json value from the curl stderr."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The thycotic_get_connection_manager_settings stderr:"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "curl_verbose_output_base64"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "dGhpc2lzbm90anNvbg==" # The base64 encoding of thisisnotjson
    End
  End
  Describe "when the curl call stderr is json but does not include the curl_information_json element"
    do_before_1() {
      # This can't be simulated by mocking thycotic_get_connection_manager_settings_curl_command(), but only my mocking thycotic_get_connection_manager_settings().
      thycotic_get_connection_manager_settings() { echo -n "blah"; echo >&2 '{"foo":"bar"}'; return 0; }
    }
    Before "do_before_1"
    It "should fail and report an error"
      When call validate_thycotic_api_access_token
      The status should be failure
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Error: Failed to check the validity of the Thycotic API Access Token."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Message UUID: cd6f780f-8fd6-4f57-b62c-9d7f04d6e01a"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Failed to get the curl_information_json value from the curl stderr."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The thycotic_get_connection_manager_settings stderr:"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "foo"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "bar"
    End
  End
  Describe "when the curl call stderr is json but does not include the curl_verbose_output_base64 element"
    do_before_1() {
      # This can't be simulated by mocking thycotic_get_connection_manager_settings_curl_command(), but only my mocking thycotic_get_connection_manager_settings().
      thycotic_get_connection_manager_settings() { echo -n "blah"; echo >&2 '{"curl_information_json":"hello"}'; return 0; }
    }
    Before "do_before_1"
    It "should fail and report an error"
      When call validate_thycotic_api_access_token
      The status should be failure
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Error: Failed to check the validity of the Thycotic API Access Token."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Message UUID: 2567f338-d875-495e-9c5d-c64b34224060"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Failed to get the curl_verbose_output_base64 value from the curl stderr."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The thycotic_get_connection_manager_settings stderr:"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "curl_information_json"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "hello"
    End
  End
  Describe "when thycotic_get_connection_manager_settings call fails"
    do_before_1() {
      thycotic_get_connection_manager_settings_curl_command_fake_rc="101"
      thycotic_get_connection_manager_settings_curl_command_fake_stderr='___CURL_OUTPUT___CURL_INFORMATION_JSON___{"errormsg":"dummy_error_message_from_curl"}'
    }
    Before "do_before_1"
    It "should fail and report an error"
      When call validate_thycotic_api_access_token
      The status should be failure
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Error: Failed to check the validity of the Thycotic API Access Token."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Message UUID: 4f89664d-3474-4a9b-8081-1d26faace922"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The curl command to validate the Thycotic access token failed with return code: 101"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The curl error message: dummy_error_message_from_curl"
    End
    Describe "when the curl_information_json (curl stderr) does not contain an errormsg element"
      do_before_2() {
        thycotic_get_connection_manager_settings_curl_command_fake_stderr='___CURL_OUTPUT___CURL_INFORMATION_JSON___{"foo":"bar"}'
      }
      Before "do_before_2"
      It "should fail and report an error"
        When call validate_thycotic_api_access_token
        The status should be failure
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Error: Failed to check the validity of the Thycotic API Access Token."
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Message UUID: 4f89664d-3474-4a9b-8081-1d26faace922"
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The curl command to validate the Thycotic access token failed with return code: 101"
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Failed to get the error message (errormsg element) from the curl information JSON."
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The curl command error text is:"
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "foo"
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "bar"
      End
    End
  End
  Describe "when the curl_information_json (curl stderr) is json but it does not contain a http_code element"
    do_before_2() {
      thycotic_get_connection_manager_settings_curl_command_fake_stderr='___CURL_OUTPUT___CURL_INFORMATION_JSON___{"foo":"bar"}'
    }
    Before "do_before_2"
    It "should fail and report an error"
      When call validate_thycotic_api_access_token
      The status should be failure
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Error: Failed to check the validity of the Thycotic API Access Token."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Message UUID: eefe6d0d-13da-47b6-852f-a2f34b0d1730"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Failed to get the HTTP status code (http_code element) from the curl information JSON."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The curl information JSON is:"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "foo"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "bar"
    End
  End
  Describe "when the http_code value is not 200"
    do_before_2() {
      thycotic_get_connection_manager_settings_curl_command_fake_stdout='{"message":"the curl get connection manager settings error message"}'
      thycotic_get_connection_manager_settings_curl_command_fake_stderr='___CURL_OUTPUT___CURL_INFORMATION_JSON___{"http_code":"501"}'
    }
    Before "do_before_2"
    It "should exit with status code 101 and report a warning of the invalid token"
      When call validate_thycotic_api_access_token
      The status should equal 101
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Warning: The provided Thycotic API Access Token is invalid or expired and won't be used. (See: thycotic_cli authenticate --help)"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Message UUID: 29d0ffda-8d2e-451b-982c-b5ecf563f6c1"
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The HTTP status code for the token validation to Thycotic was: 501  (expected 200)."
      The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Thycotic token validation error message: the curl get connection manager settings error message"
    End
    Describe "when the stdout does not contain the message element"
      do_before_3() {
        thycotic_get_connection_manager_settings_curl_command_fake_stdout='{"foo":"bar"}'
      }
      Before "do_before_3"
      It "should exit with status code 101 and report a warning of the invalid token"
        When call validate_thycotic_api_access_token
        The status should equal 101
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Warning: The provided Thycotic API Access Token is invalid or expired and won't be used. (See: thycotic_cli authenticate --help)"
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Message UUID: 29d0ffda-8d2e-451b-982c-b5ecf563f6c1"
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "The HTTP status code for the token validation to Thycotic was: 501  (expected 200)."
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Failed to get the error message (message element) from the Thycotic token validation response JSON."
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "Thycotic token validation response JSON:"
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "foo"
        The stderr should satisfy json_element_base64_decoded_should_include ".error_message_base64" "bar"
      End
    End
  End
  It "should succeed"
    # Success conditions are set at the start of this describe.
    When call validate_thycotic_api_access_token
    The status should be success
  End
End

Describe "parse_script_params"
  Describe "when the THYCOTIC_CLI_THYCOTIC_HOST_URL envvar is not set"
    unset_THYCOTIC_CLI_THYCOTIC_HOST_URL() {
      unset THYCOTIC_CLI_THYCOTIC_HOST_URL
    }
    Before "unset_THYCOTIC_CLI_THYCOTIC_HOST_URL"
    Describe "when the --thycotic_host_url parameter is not provided"
      It "reports error and exits with error status code"
        When run script "${script_under_test}"
        The status should be failure
        The stderr should include "Error: Missing required parameter: thycotic_host_url"
        The stderr should include "Use --help for usage help"
      End
    End
    Describe "when the --thycotic_host_url parameter is provided"
      It "exits with success status code (for a valid command)"
        When run script "${script_under_test}" --thycotic_host_url="dummy" authenticate --help
        The status should be success
        The stdout should include "Usage: thycotic_cli.sh authenticate" # for the 'valid' command used in this test
      End
    End
  End
  Describe "when the --access_token parameter is provided"
    It "exits with success status code (for a valid command)"
      When run script "${script_under_test}" --access_token="dummy_access_token" authenticate --help
      The status should be success
      The stdout should include "Usage: thycotic_cli.sh authenticate" # for the 'valid' command used in this test
    End
  End
  Describe "when an unknown parameter is provided"
    It "reports the error and exist with error status"
      When run script "${script_under_test}" --not-a-valid-parameter
      The status should be failure
      The stderr should include "Error: Unknown parameter: --not-a-valid-parameter"
      The stderr should include "Use --help for usage help"
    End
  End
  Describe "when no command is given"
    It "reports error and exists with error status"
      When run script "${script_under_test}"
      The status should be failure
      The stderr should include "Error: Missing required argument: command"
      The stderr should include "Use --help for usage help"
    End
  End
End

Describe "parse_script_params2"
  Include "${script_under_test}"
  Include "/usr/local/bin/capture_stdout_and_stderr.sh"

  Describe "when called with --help"
    It "should should show usage and return status 10"
      When call parse_script_params --help
      The status should equal 10
      The stdout should include "Usage:"
    End
  End
  Describe "when called with --version"
    It "should should version info and return status 10"
      When call parse_script_params --version
      The status should equal 10
      The stdout should include "thycotic_cli version"
    End
  End
  Describe "when called with --script_debug --help"
    do_before_1() { initialize_true_and_false_strings; }
    Before "do_before_1"
    It "should should show usage and return status 10 and SCRIPT_DEBUG_OPTION should be true"
      When call parse_script_params --script_debug --help
      The status should equal 10
      The variable SCRIPT_DEBUG_OPTION should equal "true"
      The stdout should include "Usage:"
    End
  End
  Describe "when called with --script_debug --version"
    do_before_1() { initialize_true_and_false_strings; }
    Before "do_before_1"
    It "should should show usage and return status 10 and SCRIPT_DEBUG_OPTION should be true"
      When call parse_script_params --script_debug --version
      The status should equal 10
      The variable SCRIPT_DEBUG_OPTION should equal "true"
      The stdout should include "thycotic_cli version"
    End
  End
  Describe "when called with --script_debug"
    do_before_1() { initialize_true_and_false_strings; }
    Before "do_before_1"
    It "should should show usage and return status 10 and SCRIPT_DEBUG_OPTION should be true"
      When call parse_script_params --script_debug
      The status should equal 1
      The variable SCRIPT_DEBUG_OPTION should equal "true"
      The stderr should include "Error: Missing required argument: command"
      The stderr should include "Use --help for usage help"
    End
  End
End
