#!/usr/bin/env bash

# Interact with Thycotic from the command line.

usage()
{
  cat <<USAGE_TEXT
Usage:  ${THIS_SCRIPT_NAME}
            [--thycotic_host_url=<url>]
            [--access_token=<token>]
            [--help | -h]
            [--version]
            [--script_debug]
            <command> [<args>]

Interact with Thycotic from the command line.

Available commands:
  get_secret              Return a secret JSON structure
  get_secret_field_value  Return the value of a secret field
  authenticate            Return an authentication token

General parameters:
    --thycotic_host_url=<url>
        The base URL of the Thycotic API service (e.g. https://my-thycotic-secret-server.com) (required if not otherwise provided, see below)
    --access_token=<token>
        The API access token with which to access Thycotic (optional, see notes below)
    --help, -h
        Print this help and exit.
    --version
        Print version info and exit.
    --script_debug
        Print script debug info.

Thycotic Host URL
  If --thycotic_host_url is not supplied, the environment variable THYCOTIC_CLI_THYCOTIC_HOST_URL will be used.

Access Token
  The API access token may alternatively be provided by setting the environment variable THYCOTIC_CLI_THYCOTIC_API_ACCESS_TOKEN.

  If the API access token isn't provided then the user will be prompted for their credentials to thycotic.

  If the user needs to be prompted for their credentials, the following environment variables are used if set:
    THYCOTIC_CLI_GET_USERNAME_COMMAND    if set, the contained command is run to obtain the user's username
    THYCOTIC_CLI_GET_PASSWORD_COMMAND    if set, the contained command is run to obtain the user's password

See '${THIS_SCRIPT_NAME} <command> --help' for help on a specific command.
USAGE_TEXT
}

usage_get_secret()
{
  cat <<USAGE_TEXT
Usage: ${THIS_SCRIPT_NAME} get_secret <args>

Get a secret.

Parameters:
  --secret_id=<id>
      The ID of the secret to return (required)
USAGE_TEXT
}

usage_get_secret_field_value()
{
  cat <<USAGE_TEXT
Usage: ${THIS_SCRIPT_NAME} get_secret_field_value <args>

Get the value of a field of a secret.

Parameters:
  --secret_id=<id>
      The ID of the secret to return (required)
  --field_slug=<slug>
      The field 'slug' of the 'SecretItem' of the secret to return (required)
USAGE_TEXT
}

usage_authenticate()
{
  cat <<USAGE_TEXT
Usage: ${THIS_SCRIPT_NAME} authenticate

Get an API access token.

Use the following to save the token:
$ export THYCOTIC_CLI_THYCOTIC_API_ACCESS_TOKEN="\$(${THIS_SCRIPT_NAME} authenticate)"
USAGE_TEXT
}

main()
{
  # Declare the variables that get set from supporting scripts/functions (so that shellcheck does not complain about seeing them referenced but not assigned in this script).
  local catch_stdouterr__rc
  local catch_stdouterr__stdout
  local catch_stdouterr__stderr
  initialize
  parse_script_params "${@}"
  last_command_return_code="$?"
  if [ "${last_command_return_code}" -gt 0 ]; then
    if [ "${last_command_return_code}" -eq 10 ]; then
      return 0
    fi
    return 1
  fi
  unset THYCOTIC_CLI_CURL_ENABLE_VERBOSE
  if [ "${SCRIPT_DEBUG_OPTION}" == "${TRUE_STRING}" ]; then
    THYCOTIC_CLI_CURL_ENABLE_VERBOSE="${TRUE_STRING}"
#    set -x
  fi
  case "${THYCOTIC_CLI_COMMAND}" in
    get_secret)
      handle_command_get_secret "${@}"
      ;;
    get_secret_field_value)
      handle_command_get_secret_field_value "${@}"
      ;;
    authenticate)
      handle_command_authenticate "${@}"
      ;;
    *)
      echo >&2 "Error: Unknown command: ${THYCOTIC_CLI_COMMAND}"
      echo >&2 "Use --help for usage help"
      return 1
      ;;
  esac
}

handle_command_get_secret()
{
  parse_script_params_get_secret "${@}" || { echo >&2 "Error: Failed to parse get_secret parameters."; return 6; }
  ensure_thycotic_api_access_token_is_held || { echo >&2 "Error: Failed to validate/get thycotic api access token."; return 5; }
  call_capture_stdout_and_stderr get_thycotic_secret || { echo >&2 "Error: Failed to get the secret."; return 7; }
  get_thycotic_secret__rc="${catch_stdouterr__rc}"
  get_thycotic_secret__stderr="${catch_stdouterr__stderr}"
  get_thycotic_secret__stdout="${catch_stdouterr__stdout}"
  if [ "${THYCOTIC_CLI_CURL_ENABLE_VERBOSE}" = "${TRUE_STRING}" ]; then
    echo >&2 "curl verbose output (get_thycotic_secret):"
    call_capture_stdout_and_stderr get_json_element_value .curl_verbose_output_base64 get_thycotic_secret__stderr
    base64 >&2 --decode <<<"${catch_stdouterr__stdout}"
    echo >&2
  fi
  if [ "${get_thycotic_secret__rc}" -gt 0 ]; then
    echo >&2 "${get_thycotic_secret__stderr}"
    return 1
  fi
  echo "${get_thycotic_secret__stdout}"
  return 0
}

handle_command_get_secret_field_value()
{
  parse_script_params_get_secret_field_value "${@}" || { echo >&2 "Error: Failed to parse get_secret_field parameters."; return 6; }
  ensure_thycotic_api_access_token_is_held || { echo >&2 "Error: Failed to validate/get thycotic api access token."; return 5; }
  call_capture_stdout_and_stderr get_thycotic_secret_field_value || { echo >&2 "Error: Failed to get the secret field value."; return 7; }
  get_thycotic_secret_field_value__rc="${catch_stdouterr__rc}"
  get_thycotic_secret_field_value__stderr="${catch_stdouterr__stderr}"
  get_thycotic_secret_field_value__stdout="${catch_stdouterr__stdout}"
  if [ "${THYCOTIC_CLI_CURL_ENABLE_VERBOSE}" = "${TRUE_STRING}" ]; then
    echo >&2 "curl verbose output (get_thycotic_secret_field_value):"
    call_capture_stdout_and_stderr get_json_element_value .curl_verbose_output_base64 get_thycotic_secret_field_value__stderr
    base64 >&2 --decode <<<"${catch_stdouterr__stdout}"
    echo >&2
  fi
  if [ "${get_thycotic_secret_field_value__rc}" -gt 0 ]; then
    echo >&2 "${get_thycotic_secret_field_value__stderr}"
    return 1
  fi
  echo "${get_thycotic_secret_field_value__stdout}"
  return 0
}

handle_command_authenticate()
{
  parse_script_params_authenticate "${@}" || { echo >&2 "Error: Failed to parse authenticate parameters."; return 6; }
  unset THYCOTIC_CLI_THYCOTIC_API_ACCESS_TOKEN
  ensure_thycotic_api_access_token_is_held || { echo >&2 "Error: Failed to validate/get thycotic api access token."; return 5; }
  echo "${THYCOTIC_CLI_THYCOTIC_API_ACCESS_TOKEN}"
}

ensure_thycotic_api_access_token_is_held()
  # This method must not be called using call_capture_stdout_and_stderr
  # as it contains user interactive calls (get username/password).
{
  if [ -n "${THYCOTIC_CLI_THYCOTIC_API_ACCESS_TOKEN}" ]; then
    call_capture_stdout_and_stderr validate_thycotic_api_access_token
    validate_thycotic_api_access_token__rc="${catch_stdouterr__rc}"
    validate_thycotic_api_access_token__stderr="${catch_stdouterr__stderr}"
    #validate_thycotic_api_access_token__stdout="${catch_stdouterr__stdout}"
    if [ "${validate_thycotic_api_access_token__rc}" -gt 0 ]; then
      call_capture_stdout_and_stderr get_json_element_value .error_message_base64 validate_thycotic_api_access_token__stderr
      if [ "${catch_stdouterr__rc}" -gt 0 ]; then
        echo >&2 "Error: Failed to get the validate_thycotic_api_access_token error message."
        echo >&2 "get_json_element_value return code: ${catch_stdouterr__rc}"
        echo >&2 "get_json_element_value error message: ${catch_stdouterr__stderr}"
        echo >&2 "validate_thycotic_api_access_token__stderr: ${validate_thycotic_api_access_token__stderr}"
        return 1
      fi
      validate_thycotic_api_access_token__error_message="$(base64 --decode <<<"${catch_stdouterr__stdout}")"
      if [ "${validate_thycotic_api_access_token__rc}" -eq 101 ]; then
        # The access token is invalid.
        echo >&2 "${validate_thycotic_api_access_token__error_message}"
        unset THYCOTIC_CLI_THYCOTIC_API_ACCESS_TOKEN
      else
        # An error occurred validating the current access token.
        echo >&2 "Error: Failed to validate the existing access token."
        echo >&2 "${validate_thycotic_api_access_token__error_message}"
        return 1
      fi
    fi
  fi
  if [ -z "${THYCOTIC_CLI_THYCOTIC_API_ACCESS_TOKEN}" ]; then
    get_user_username
    get_user_password
    call_capture_stdout_and_stderr get_thycotic_api_access_token
    get_thycotic_api_access_token__rc="${catch_stdouterr__rc}"
    get_thycotic_api_access_token__stderr="${catch_stdouterr__stderr}"
    get_thycotic_api_access_token__stdout="${catch_stdouterr__stdout}"
    if [ "${get_thycotic_api_access_token__rc}" -gt 0 ]; then
      echo >&2 "/-----------------------------------------------------------"
      echo >&2 "Error: Failed to get an access token."
      call_capture_stdout_and_stderr get_json_element_value .error_message_base64 get_thycotic_api_access_token__stderr
      if [ "${catch_stdouterr__rc}" -gt 0 ]; then
        echo >&2 "Error: Failed to get the get_thycotic_api_access_token error message."
        echo >&2 "get_json_element_value return code: ${catch_stdouterr__rc}"
        echo >&2 "get_json_element_value error message: ${catch_stdouterr__stderr}"
        echo >&2 "get_thycotic_api_access_token__stderr: ${get_thycotic_api_access_token__stderr}"
      else
        echo >&2 "The get_thycotic_api_access_token error message:"
        echo >&2 "$(base64 --decode <<<"${catch_stdouterr__stdout}")<<<<"
      fi
      if [ "${THYCOTIC_CLI_CURL_ENABLE_VERBOSE}" = "${TRUE_STRING}" ]; then
        echo >&2 "curl verbose output (get_thycotic_api_access_token):"
        call_capture_stdout_and_stderr get_json_element_value .curl_verbose_output_base64 get_thycotic_api_access_token__stderr
        base64 >&2 --decode <<<"${catch_stdouterr__stdout}"
        echo >&2
      fi
      echo >&2 "\-----------------------------------------------------------"
      return 1
    fi
    if [ "${THYCOTIC_CLI_CURL_ENABLE_VERBOSE}" = "${TRUE_STRING}" ]; then
      echo >&2 "curl verbose output (get_thycotic_api_access_token):"
      call_capture_stdout_and_stderr get_json_element_value .curl_verbose_output_base64 get_thycotic_api_access_token__stderr
      base64 >&2 --decode <<<"${catch_stdouterr__stdout}"
      echo >&2
    fi
    THYCOTIC_CLI_THYCOTIC_API_ACCESS_TOKEN="${get_thycotic_api_access_token__stdout}"
  fi
}

get_thycotic_secret()
{
  local error_message
  local error_response
  call_capture_stdout_and_stderr thycotic_get_secret
  thycotic_get_secret__rc="${catch_stdouterr__rc}"
  thycotic_get_secret__response_json="${catch_stdouterr__stdout}"
  thycotic_get_secret__curl_full_json_stderr="${catch_stdouterr__stderr}"
  # Get the curl information json value.
  call_capture_stdout_and_stderr get_json_element_value .curl_information_json thycotic_get_secret__curl_full_json_stderr
  if [ "${catch_stdouterr__rc}" -gt 0 ]; then
    error_message+="/-----------------------------------------------------------"$'\n'
    error_message+="Error: Failed to get the secret."$'\n'
    error_message+="Message UUID: 5832ab7a-7df8-44ef-925e-528fded45bbb"$'\n'
    error_message+="Failed to get the curl_information_json value from the curl stderr."$'\n'
    error_message+="get_json_element_value return code: ${catch_stdouterr__rc}"$'\n'
    error_message+="get_json_element_value error message: ${catch_stdouterr__stderr}"$'\n'
    error_message+="The thycotic_get_secret stderr:"$'\n'
    error_message+="${thycotic_get_secret__curl_full_json_stderr}"$'\n'
    error_message+="\-----------------------------------------------------------"$'\n'
    error_response='{'
    error_response+='"error_message_base64":"'"$(base64 --wrap=0 <<<"${error_message}")"'"'
    error_response+='}'
    echo >&2 "${error_response}"
    return 15
  fi
  thycotic_get_secret__curl_information_json="${catch_stdouterr__stdout}"
  # Get the curl verbose output.
  call_capture_stdout_and_stderr get_json_element_value .curl_verbose_output_base64 thycotic_get_secret__curl_full_json_stderr
  if [ "${catch_stdouterr__rc}" -gt 0 ]; then
    error_message+="/-----------------------------------------------------------"$'\n'
    error_message+="Error: Failed to get the secret."$'\n'
    error_message+="Message UUID: 77f637de-b006-48d9-8b2d-f153f88e85e5"$'\n'
    error_message+="Failed to get the curl_verbose_output_base64 value from the curl stderr."$'\n'
    error_message+="get_json_element_value return code: ${catch_stdouterr__rc}"$'\n'
    error_message+="get_json_element_value error message: ${catch_stdouterr__stderr}"$'\n'
    error_message+="The thycotic_get_secret stderr:"$'\n'
    error_message+="${thycotic_get_secret__curl_full_json_stderr}"$'\n'
    error_message+="\-----------------------------------------------------------"$'\n'
    error_response='{'
    error_response+='"error_message_base64":"'"$(base64 --wrap=0 <<<"${error_message}")"'"'
    error_response+='}'
    echo >&2 "${error_response}"
    return 16
  fi
  thycotic_get_secret__curl_verbose_output_base64="${catch_stdouterr__stdout}"
  # Check that the thycotic_get_secret_field call succeeded.
  if [ "${thycotic_get_secret__rc}" -gt 0 ]; then
    error_message+="/-----------------------------------------------------------"$'\n'
    error_message+="Error: Failed to get the secret."$'\n'
    error_message+="Message UUID: 7b8f8276-ee2f-4040-a8ba-c9fe657419f9"$'\n'
    error_message+="The curl command to get the secret from Thycotic failed with return code: ${thycotic_get_secret__rc}"$'\n'
    call_capture_stdout_and_stderr get_json_element_value .errormsg thycotic_get_secret__curl_information_json
    if [ "${catch_stdouterr__rc}" -gt 0 ]; then
      error_message+="Failed to get the error message (errormsg element) from the curl information JSON."$'\n'
      error_message+="get_json_element_value return code: ${catch_stdouterr__rc}"$'\n'
      error_message+="get_json_element_value error message: ${catch_stdouterr__stderr}"$'\n'
      error_message+="The curl command error text is:"$'\n'
      error_message+="${thycotic_get_secret__curl_information_json}"$'\n'
    else
      error_message+="The curl error message: ${catch_stdouterr__stdout}"$'\n'
    fi
    error_message+="\-----------------------------------------------------------"$'\n'
    error_response='{'
    error_response+='"error_message_base64":"'"$(base64 --wrap=0 <<<"${error_message}")"'"'
    if [ "${THYCOTIC_CLI_CURL_ENABLE_VERBOSE}" = "${TRUE_STRING}" ]; then
      error_response+=',"curl_verbose_output_base64":"'"${thycotic_get_secret__curl_verbose_output_base64}"'"'
    fi
    error_response+='}'
    echo >&2 "${error_response}"
    return 1
  fi
  # Check that the HTTP status is 200
  call_capture_stdout_and_stderr get_http_code_from_curl_information_json thycotic_get_secret__curl_information_json
  if [ "${catch_stdouterr__rc}" -gt 0 ]; then
    error_message+="/-----------------------------------------------------------"$'\n'
    error_message+="Error: Failed to get the secret."$'\n'
    error_message+="Message UUID: ba36113f-88a6-4564-a169-e83938b16b12"$'\n'
    error_message+="Failed to get the HTTP status code (http_code element) from the curl information JSON."$'\n'
    error_message+="get_http_code_from_curl_information_json return code: ${catch_stdouterr__rc}"$'\n'
    error_message+="get_http_code_from_curl_information_json error message: ${catch_stdouterr__stderr}"$'\n'
    error_message+="The curl information JSON is:"$'\n'
    error_message+="${thycotic_get_secret__curl_information_json}"$'\n'
    error_message+="\-----------------------------------------------------------"$'\n'
    error_response='{'
    error_response+='"error_message_base64":"'"$(base64 --wrap=0 <<<"${error_message}")"'"'
    if [ "${THYCOTIC_CLI_CURL_ENABLE_VERBOSE}" = "${TRUE_STRING}" ]; then
      error_response+=',"curl_verbose_output_base64":"'"${thycotic_get_secret__curl_verbose_output_base64}"'"'
    fi
    error_response+='}'
    echo >&2 "${error_response}"
    return 1
  fi
  curl__http_code="${catch_stdouterr__stdout}"
  if [ "${curl__http_code}" != "200" ]; then
    error_message+="/-----------------------------------------------------------"$'\n'
    error_message+="Error: Failed to get the secret."$'\n'
    error_message+="Message UUID: f4cec091-8a20-43ec-865f-cd543ec335b3"$'\n'
    error_message+="The HTTP status code for the 'get secret' call to Thycotic was: ${curl__http_code}  (expected 200)."$'\n'
    call_capture_stdout_and_stderr get_json_element_value .error thycotic_get_secret__response_json
    if [ "${catch_stdouterr__rc}" -gt 0 ]; then
      error_message+="Failed to get the error message (error element) from the Thycotic get secret response JSON."$'\n'
      error_message+="Thycotic get secret response JSON:"$'\n'
      error_message+="${thycotic_get_secret__response_json}"$'\n'
    else
      error_message+="Thycotic get secret error message: ${catch_stdouterr__stdout}"$'\n'
    fi
    error_message+="\-----------------------------------------------------------"$'\n'
    error_response='{'
    error_response+='"error_message_base64":"'"$(base64 --wrap=0 <<<"${error_message}")"'"'
    if [ "${THYCOTIC_CLI_CURL_ENABLE_VERBOSE}" = "${TRUE_STRING}" ]; then
      error_response+=',"curl_verbose_output_base64":"'"${thycotic_get_secret__curl_verbose_output_base64}"'"'
    fi
    error_response+='}'
    echo >&2 "${error_response}"
    return 1
  fi
  # HTTP status is 200 OK
  # Check that the Content-Type is (or rather, contains) application/json
  call_capture_stdout_and_stderr get_json_element_value .content_type thycotic_get_secret__curl_information_json
  if [ "${catch_stdouterr__rc}" -gt 0 ]; then
    error_message+="/-----------------------------------------------------------"$'\n'
    error_message+="Error: Failed to get the secret."$'\n'
    error_message+="Message UUID: 7bd848d3-46ef-4499-bd4e-e4e783e2f542"$'\n'
    error_message+="Failed to get the Content-Type value (content_type element) from the curl information JSON."$'\n'
    error_message+="get_json_element_value return code: ${catch_stdouterr__rc}"$'\n'
    error_message+="get_json_element_value error message: ${catch_stdouterr__stderr}"$'\n'
    error_message+="The curl information JSON is:"$'\n'
    error_message+="${thycotic_get_secret__curl_information_json}"$'\n'
    error_message+="\-----------------------------------------------------------"$'\n'
    error_response='{'
    error_response+='"error_message_base64":"'"$(base64 --wrap=0 <<<"${error_message}")"'"'
    if [ "${THYCOTIC_CLI_CURL_ENABLE_VERBOSE}" = "${TRUE_STRING}" ]; then
      error_response+=',"curl_verbose_output_base64":"'"${thycotic_get_secret__curl_verbose_output_base64}"'"'
    fi
    error_response+='}'
    echo >&2 "${error_response}"
    return 1
  fi
  case ${catch_stdouterr__stdout} in
    *application/json* )
      # Content-Type is application/json
      call_capture_stdout_and_stderr get_json_element_value . thycotic_get_secret__response_json
      if [ "${catch_stdouterr__rc}" -gt 0 ]; then
        error_message+="/-----------------------------------------------------------"$'\n'
        error_message+="Error: Failed to get the secret."$'\n'
        error_message+="Message UUID: f9df7043-8a3c-47a3-b6b8-aa629a0fdcdc"$'\n'
        error_message+="Failed to parse the response as JSON when the content type was application/json"$'\n'
        error_message+="Parse JSON return code: ${catch_stdouterr__rc}"$'\n'
        error_message+="Parse JSON error message: ${catch_stdouterr__stderr}"$'\n'
        error_message+="Thycotic get secret response JSON:"$'\n'
        error_message+="${thycotic_get_secret__response_json}"$'\n'
        error_message+="\-----------------------------------------------------------"$'\n'
        error_response='{'
        error_response+='"error_message_base64":"'"$(base64 --wrap=0 <<<"${error_message}")"'"'
        if [ "${THYCOTIC_CLI_CURL_ENABLE_VERBOSE}" = "${TRUE_STRING}" ]; then
          error_response+=',"curl_verbose_output_base64":"'"${thycotic_get_secret__curl_verbose_output_base64}"'"'
        fi
        error_response+='}'
        echo >&2 "${error_response}"
        return 1
      fi
      THYCOTIC_CLI_SECRET_JSON="${catch_stdouterr__stdout}"
      ;;
    * )
      error_message+="/-----------------------------------------------------------"$'\n'
      error_message+="Error: Failed to get the secret."$'\n'
      error_message+="Message UUID: 30ebc3eb-ab9e-4200-a4f4-b378ae093249"$'\n'
      error_message+="Unexpected content type: ${catch_stdouterr__stdout}"$'\n'
      error_message+="Thycotic get secret response JSON:"$'\n'
      error_message+="${thycotic_get_secret__response_json}"$'\n'
      error_message+="\-----------------------------------------------------------"$'\n'
      error_response='{'
      error_response+='"error_message_base64":"'"$(base64 --wrap=0 <<<"${error_message}")"'"'
      if [ "${THYCOTIC_CLI_CURL_ENABLE_VERBOSE}" = "${TRUE_STRING}" ]; then
        error_response+=',"curl_verbose_output_base64":"'"${thycotic_get_secret__curl_verbose_output_base64}"'"'
      fi
      error_response+='}'
      echo >&2 "${error_response}"
      return 1
      ;;
  esac
  # If verbose output is enabled, also output the curl verbose output base64.
  if [ "${THYCOTIC_CLI_CURL_ENABLE_VERBOSE}" = "${TRUE_STRING}" ]; then
    echo >&2 '{"curl_verbose_output_base64":"'"${thycotic_get_secret__curl_verbose_output_base64}"'"}'
  fi
  echo "${THYCOTIC_CLI_SECRET_JSON}"
}

get_thycotic_secret_field_value()
{
  local error_message
  local error_response
  call_capture_stdout_and_stderr thycotic_get_secret_field
  thycotic_get_secret_field__rc="${catch_stdouterr__rc}"
  thycotic_get_secret_field__response_json="${catch_stdouterr__stdout}"
  thycotic_get_secret_field__curl_full_json_stderr="${catch_stdouterr__stderr}"
  # Get the curl information json value from the curl call stderr.
  call_capture_stdout_and_stderr get_json_element_value .curl_information_json thycotic_get_secret_field__curl_full_json_stderr
  if [ "${catch_stdouterr__rc}" -gt 0 ]; then
    error_message+="/-----------------------------------------------------------"$'\n'
    error_message+="Error: Failed to get the secret field value."$'\n'
    error_message+="Message UUID: f21774c1-fe3b-4c17-89dc-d1b119fb9566"$'\n'
    error_message+="Failed to get the curl_information_json value from the curl stderr."$'\n'
    error_message+="get_json_element_value return code: ${catch_stdouterr__rc}"$'\n'
    error_message+="get_json_element_value error message: ${catch_stdouterr__stderr}"$'\n'
    error_message+="The thycotic_get_secret_field stderr:"$'\n'
    error_message+="${thycotic_get_secret_field__curl_full_json_stderr}"$'\n'
    error_message+="\-----------------------------------------------------------"$'\n'
    error_response='{'
    error_response+='"error_message_base64":"'"$(base64 --wrap=0 <<<"${error_message}")"'"'
    error_response+='}'
    echo >&2 "${error_response}"
    return 15
  fi
  thycotic_get_secret_field__curl_information_json="${catch_stdouterr__stdout}"
  # Get the curl verbose output.
  call_capture_stdout_and_stderr get_json_element_value .curl_verbose_output_base64 thycotic_get_secret_field__curl_full_json_stderr
  if [ "${catch_stdouterr__rc}" -gt 0 ]; then
    error_message+="/-----------------------------------------------------------"$'\n'
    error_message+="Error: Failed to get the secret field value."$'\n'
    error_message+="Message UUID: 10ffc22f-e521-4e7b-9e6e-8344316647c2"$'\n'
    error_message+="Failed to get the curl_verbose_output_base64 value from the curl stderr."$'\n'
    error_message+="get_json_element_value return code: ${catch_stdouterr__rc}"$'\n'
    error_message+="get_json_element_value error message: ${catch_stdouterr__stderr}"$'\n'
    error_message+="The thycotic_get_secret_field stderr:"$'\n'
    error_message+="${thycotic_get_secret_field__curl_full_json_stderr}"$'\n'
    error_message+="\-----------------------------------------------------------"$'\n'
    error_response='{'
    error_response+='"error_message_base64":"'"$(base64 --wrap=0 <<<"${error_message}")"'"'
    error_response+='}'
    echo >&2 "${error_response}"
    return 16
  fi
  thycotic_get_secret_field__curl_verbose_output_base64="${catch_stdouterr__stdout}"
  # Check that the thycotic_get_secret_field call succeeded.
  if [ "${thycotic_get_secret_field__rc}" -gt 0 ]; then
    error_message+="/-----------------------------------------------------------"$'\n'
    error_message+="Error: Failed to get the secret field value."$'\n'
    error_message+="Message UUID: 2b2f7369-0e85-49f1-b8bc-b819fcb8bc66"$'\n'
    error_message+="The curl command to get the secret field from Thycotic failed with return code: ${thycotic_get_secret_field__rc}"$'\n'
    call_capture_stdout_and_stderr get_json_element_value .errormsg thycotic_get_secret_field__curl_information_json
    if [ "${catch_stdouterr__rc}" -gt 0 ]; then
      error_message+="Failed to get the error message (errormsg element) from the curl information JSON."$'\n'
      error_message+="get_json_element_value return code: ${catch_stdouterr__rc}"$'\n'
      error_message+="get_json_element_value error message: ${catch_stdouterr__stderr}"$'\n'
      error_message+="The curl command error text is:"$'\n'
      error_message+="${thycotic_get_secret_field__curl_information_json}"$'\n'
    else
      error_message+="The curl error message: ${catch_stdouterr__stdout}"$'\n'
    fi
    error_message+="\-----------------------------------------------------------"$'\n'
    error_response='{'
    error_response+='"error_message_base64":"'"$(base64 --wrap=0 <<<"${error_message}")"'"'
    if [ "${THYCOTIC_CLI_CURL_ENABLE_VERBOSE}" = "${TRUE_STRING}" ]; then
      error_response+=',"curl_verbose_output_base64":"'"${thycotic_get_secret_field__curl_verbose_output_base64}"'"'
    fi
    error_response+='}'
    echo >&2 "${error_response}"
    return 1
  fi
  # Check that the HTTP status is 200
  call_capture_stdout_and_stderr get_http_code_from_curl_information_json thycotic_get_secret_field__curl_information_json
  if [ "${catch_stdouterr__rc}" -gt 0 ]; then
    error_message+="/-----------------------------------------------------------"$'\n'
    error_message+="Error: Failed to get the secret field value."$'\n'
    error_message+="Message UUID: 7ffd878a-04c9-473a-ae46-e049c8af5d5b"$'\n'
    error_message+="Failed to get the HTTP status code (http_code element) from the curl information JSON."$'\n'
    error_message+="get_http_code_from_curl_information_json return code: ${catch_stdouterr__rc}"$'\n'
    error_message+="get_http_code_from_curl_information_json error message: ${catch_stdouterr__stderr}"$'\n'
    error_message+="The curl information JSON is:"$'\n'
    error_message+="${thycotic_get_secret_field__curl_information_json}"$'\n'
    error_message+="\-----------------------------------------------------------"$'\n'
    error_response='{'
    error_response+='"error_message_base64":"'"$(base64 --wrap=0 <<<"${error_message}")"'"'
    if [ "${THYCOTIC_CLI_CURL_ENABLE_VERBOSE}" = "${TRUE_STRING}" ]; then
      error_response+=',"curl_verbose_output_base64":"'"${thycotic_get_secret_field__curl_verbose_output_base64}"'"'
    fi
    error_response+='}'
    echo >&2 "${error_response}"
    return 1
  fi
  curl__http_code="${catch_stdouterr__stdout}"
  if [ "${curl__http_code}" != "200" ]; then
    error_message+="/-----------------------------------------------------------"$'\n'
    error_message+="Error: Failed to get the secret field value."$'\n'
    error_message+="Message UUID: 1d97aa42-732b-4880-84f6-b2137b48cfa9"$'\n'
    error_message+="The HTTP status code for the 'get secret field' call to Thycotic was: ${curl__http_code}  (expected 200)."$'\n'
    call_capture_stdout_and_stderr get_json_element_value .error thycotic_get_secret_field__response_json
    if [ "${catch_stdouterr__rc}" -gt 0 ]; then
      error_message+="Failed to get the error message (error element) from the Thycotic get secret field response JSON."$'\n'
      error_message+="Thycotic get secret field response:"$'\n'
      error_message+="${thycotic_get_secret_field__response_json}"$'\n'
    else
      error_message+="Thycotic get secret field error message: ${catch_stdouterr__stdout}"$'\n'
    fi
    error_message+="\-----------------------------------------------------------"$'\n'
    error_response='{'
    error_response+='"error_message_base64":"'"$(base64 --wrap=0 <<<"${error_message}")"'"'
    if [ "${THYCOTIC_CLI_CURL_ENABLE_VERBOSE}" = "${TRUE_STRING}" ]; then
      error_response+=',"curl_verbose_output_base64":"'"${thycotic_get_secret_field__curl_verbose_output_base64}"'"'
    fi
    error_response+='}'
    echo >&2 "${error_response}"
    return 1
  fi
  # HTTP status is 200 OK
  # Get the Content-Type value to determine how to obtain the secret field value.
  call_capture_stdout_and_stderr get_json_element_value .content_type thycotic_get_secret_field__curl_information_json
  if [ "${catch_stdouterr__rc}" -gt 0 ]; then
    error_message+="/-----------------------------------------------------------"$'\n'
    error_message+="Error: Failed to get the secret field value."$'\n'
    error_message+="Message UUID: b82d5534-690f-41ee-83e8-94390e751381"$'\n'
    error_message+="Failed to get the Content-Type value (content_type element) from the curl information JSON."$'\n'
    error_message+="get_json_element_value return code: ${catch_stdouterr__rc}"$'\n'
    error_message+="get_json_element_value error message: ${catch_stdouterr__stderr}"$'\n'
    error_message+="The curl information JSON is:"$'\n'
    error_message+="${thycotic_get_secret_field__curl_information_json}"$'\n'
    error_message+="\-----------------------------------------------------------"$'\n'
    error_response='{'
    error_response+='"error_message_base64":"'"$(base64 --wrap=0 <<<"${error_message}")"'"'
    if [ "${THYCOTIC_CLI_CURL_ENABLE_VERBOSE}" = "${TRUE_STRING}" ]; then
      error_response+=',"curl_verbose_output_base64":"'"${thycotic_get_secret_field__curl_verbose_output_base64}"'"'
    fi
    error_response+='}'
    echo >&2 "${error_response}"
    return 1
  fi
  case ${catch_stdouterr__stdout} in
    "application/octet-stream" )
      THYCOTIC_CLI_SECRET_FIELD_VALUE="${thycotic_get_secret_field__response_json}"
      ;;
    *application/json* )
      # Content-Type is application/json
      call_capture_stdout_and_stderr get_json_element_value . thycotic_get_secret_field__response_json
      if [ "${catch_stdouterr__rc}" -gt 0 ]; then
        error_message+="/-----------------------------------------------------------"$'\n'
        error_message+="Error: Failed to get the secret field value."$'\n'
        error_message+="Message UUID: a6893c48-e73c-4930-9722-f94a09c45f61"$'\n'
        error_message+="Failed to parse the response as JSON when the content type was application/json"$'\n'
        error_message+="Parse JSON return code: ${catch_stdouterr__rc}"$'\n'
        error_message+="Parse JSON error message: ${catch_stdouterr__stderr}"$'\n'
        error_message+="Thycotic get secret field response:"$'\n'
        error_message+="${thycotic_get_secret_field__response_json}"$'\n'
        error_message+="\-----------------------------------------------------------"$'\n'
        error_response='{'
        error_response+='"error_message_base64":"'"$(base64 --wrap=0 <<<"${error_message}")"'"'
        if [ "${THYCOTIC_CLI_CURL_ENABLE_VERBOSE}" = "${TRUE_STRING}" ]; then
          error_response+=',"curl_verbose_output_base64":"'"${thycotic_get_secret_field__curl_verbose_output_base64}"'"'
        fi
        error_response+='}'
        echo >&2 "${error_response}"
        return 1
      fi
      THYCOTIC_CLI_SECRET_FIELD_VALUE="${catch_stdouterr__stdout}"
      ;;
    * )
      error_message+="/-----------------------------------------------------------"$'\n'
      error_message+="Error: Failed to get the secret field value."$'\n'
      error_message+="Message UUID: 9dfb9696-3065-4a56-aea8-cf1f883fd30d"$'\n'
      error_message+="Unexpected content type: ${catch_stdouterr__stdout}"$'\n'
      error_message+="Thycotic get secret field response:"$'\n'
      error_message+="${thycotic_get_secret_field__response_json}"$'\n'
      error_message+="\-----------------------------------------------------------"$'\n'
      error_response='{'
      error_response+='"error_message_base64":"'"$(base64 --wrap=0 <<<"${error_message}")"'"'
      if [ "${THYCOTIC_CLI_CURL_ENABLE_VERBOSE}" = "${TRUE_STRING}" ]; then
        error_response+=',"curl_verbose_output_base64":"'"${thycotic_get_secret_field__curl_verbose_output_base64}"'"'
      fi
      error_response+='}'
      echo >&2 "${error_response}"
      return 1
      ;;
  esac
  # If verbose output is enabled, also output the curl verbose output base64.
  if [ "${THYCOTIC_CLI_CURL_ENABLE_VERBOSE}" = "${TRUE_STRING}" ]; then
    echo >&2 '{"curl_verbose_output_base64":"'"${thycotic_get_secret_field__curl_verbose_output_base64}"'"}'
  fi
  echo "${THYCOTIC_CLI_SECRET_FIELD_VALUE}"
}

validate_thycotic_api_access_token()
  # Validates the thycotic access token.
  # Input:
  #   THYCOTIC_CLI_THYCOTIC_API_ACCESS_TOKEN env var - the value of the access token to validate
  # Parameters:
  #   None.
  # Return codes:
  #   0   - the access token is valid
  #   1   - an error occurred trying to validate the access token
  #   101 - the access token is invalid
{
  local error_message
  local error_response
  call_capture_stdout_and_stderr thycotic_get_connection_manager_settings
  thycotic_get_connection_manager_settings__rc="${catch_stdouterr__rc}"
  thycotic_get_connection_manager_settings__response_json="${catch_stdouterr__stdout}"
  thycotic_get_connection_manager_settings__curl_full_json_stderr="${catch_stdouterr__stderr}"
  # Get the curl information json value.
  call_capture_stdout_and_stderr get_json_element_value .curl_information_json thycotic_get_connection_manager_settings__curl_full_json_stderr
  if [ "${catch_stdouterr__rc}" -gt 0 ]; then
    error_message+="/-----------------------------------------------------------"$'\n'
    error_message+="Error: Failed to check the validity of the Thycotic API Access Token."$'\n'
    error_message+="Message UUID: cd6f780f-8fd6-4f57-b62c-9d7f04d6e01a"$'\n'
    error_message+="Failed to get the curl_information_json value from the curl stderr."$'\n'
    error_message+="get_json_element_value return code: ${catch_stdouterr__rc}"$'\n'
    error_message+="get_json_element_value error message: ${catch_stdouterr__stderr}"$'\n'
    error_message+="The thycotic_get_connection_manager_settings stderr:"$'\n'
    error_message+="${thycotic_get_connection_manager_settings__curl_full_json_stderr}"$'\n'
    error_message+="\-----------------------------------------------------------"$'\n'
    error_response='{'
    error_response+='"error_message_base64":"'"$(base64 --wrap=0 <<<"${error_message}")"'"'
    error_response+='}'
    echo >&2 "${error_response}"
    return 15
  fi
  thycotic_get_connection_manager_settings__curl_information_json="${catch_stdouterr__stdout}"
  # Get the curl verbose output.
  call_capture_stdout_and_stderr get_json_element_value .curl_verbose_output_base64 thycotic_get_connection_manager_settings__curl_full_json_stderr
  if [ "${catch_stdouterr__rc}" -gt 0 ]; then
    error_message+="/-----------------------------------------------------------"$'\n'
    error_message+="Error: Failed to check the validity of the Thycotic API Access Token."$'\n'
    error_message+="Message UUID: 2567f338-d875-495e-9c5d-c64b34224060"$'\n'
    error_message+="Failed to get the curl_verbose_output_base64 value from the curl stderr."$'\n'
    error_message+="get_json_element_value return code: ${catch_stdouterr__rc}"$'\n'
    error_message+="get_json_element_value error message: ${catch_stdouterr__stderr}"$'\n'
    error_message+="The thycotic_get_connection_manager_settings stderr:"$'\n'
    error_message+="${thycotic_get_connection_manager_settings__curl_full_json_stderr}"$'\n'
    error_message+="\-----------------------------------------------------------"$'\n'
    error_response='{'
    error_response+='"error_message_base64":"'"$(base64 --wrap=0 <<<"${error_message}")"'"'
    error_response+='}'
    echo >&2 "${error_response}"
    return 16
  fi
  thycotic_get_connection_manager_settings__curl_verbose_output_base64="${catch_stdouterr__stdout}"
  # Check that the thycotic_get_secret_field call succeeded.
  if [ "${thycotic_get_connection_manager_settings__rc}" -gt 0 ]; then
    error_message+="/-----------------------------------------------------------"$'\n'
    error_message+="Error: Failed to check the validity of the Thycotic API Access Token."$'\n'
    error_message+="Message UUID: 4f89664d-3474-4a9b-8081-1d26faace922"$'\n'
    error_message+="The curl command to validate the Thycotic access token failed with return code: ${thycotic_get_connection_manager_settings__rc}"$'\n'
    call_capture_stdout_and_stderr get_json_element_value .errormsg thycotic_get_connection_manager_settings__curl_information_json
    if [ "${catch_stdouterr__rc}" -gt 0 ]; then
      error_message+="Failed to get the error message (errormsg element) from the curl information JSON."$'\n'
      error_message+="get_json_element_value return code: ${catch_stdouterr__rc}"$'\n'
      error_message+="get_json_element_value error message: ${catch_stdouterr__stderr}"$'\n'
      error_message+="The curl command error text is:"$'\n'
      error_message+="${thycotic_get_connection_manager_settings__curl_information_json}"$'\n'
    else
      error_message+="The curl error message: ${catch_stdouterr__stdout}"$'\n'
    fi
    error_message+="\-----------------------------------------------------------"$'\n'
    error_response='{'
    error_response+='"error_message_base64":"'"$(base64 --wrap=0 <<<"${error_message}")"'"'
    if [ "${THYCOTIC_CLI_CURL_ENABLE_VERBOSE}" = "${TRUE_STRING}" ]; then
      error_response+=',"curl_verbose_output_base64":"'"${thycotic_get_connection_manager_settings__curl_verbose_output_base64}"'"'
    fi
    error_response+='}'
    echo >&2 "${error_response}"
    return 13
  fi
  # Check that the HTTP status is 200
  call_capture_stdout_and_stderr get_http_code_from_curl_information_json thycotic_get_connection_manager_settings__curl_information_json
  if [ "${catch_stdouterr__rc}" -gt 0 ]; then
    error_message+="/-----------------------------------------------------------"$'\n'
    error_message+="Error: Failed to check the validity of the Thycotic API Access Token."$'\n'
    error_message+="Message UUID: eefe6d0d-13da-47b6-852f-a2f34b0d1730"$'\n'
    error_message+="Failed to get the HTTP status code (http_code element) from the curl information JSON."$'\n'
    error_message+="get_http_code_from_curl_information_json return code: ${catch_stdouterr__rc}"$'\n'
    error_message+="get_http_code_from_curl_information_json error message: ${catch_stdouterr__stderr}"$'\n'
    error_message+="The curl information JSON is:"$'\n'
    error_message+="${thycotic_get_connection_manager_settings__curl_information_json}"$'\n'
    error_message+="\-----------------------------------------------------------"$'\n'
    error_response='{'
    error_response+='"error_message_base64":"'"$(base64 --wrap=0 <<<"${error_message}")"'"'
    if [ "${THYCOTIC_CLI_CURL_ENABLE_VERBOSE}" = "${TRUE_STRING}" ]; then
      error_response+=',"curl_verbose_output_base64":"'"${thycotic_get_connection_manager_settings__curl_verbose_output_base64}"'"'
    fi
    error_response+='}'
    echo >&2 "${error_response}"
    return 14
  fi
  curl__http_code="${catch_stdouterr__stdout}"
  if [ "${curl__http_code}" != "200" ]; then
    error_message+="/-----------------------------------------------------------"$'\n'
    error_message+="Warning: The provided Thycotic API Access Token is invalid or expired and won't be used. (See: thycotic_cli authenticate --help)"$'\n'
    error_message+="Message UUID: 29d0ffda-8d2e-451b-982c-b5ecf563f6c1"$'\n'
    error_message+="The HTTP status code for the token validation to Thycotic was: ${curl__http_code}  (expected 200)."$'\n'
    call_capture_stdout_and_stderr get_json_element_value .message thycotic_get_connection_manager_settings__response_json
    if [ "${catch_stdouterr__rc}" -gt 0 ]; then
      error_message+="Failed to get the error message (message element) from the Thycotic token validation response JSON."$'\n'
      error_message+="Thycotic token validation response JSON:"$'\n'
      error_message+="${thycotic_get_connection_manager_settings__response_json}"$'\n'
    else
      error_message+="Thycotic token validation error message: ${catch_stdouterr__stdout}"$'\n'
    fi
    error_message+="\-----------------------------------------------------------"$'\n'
    error_response='{'
    error_response+='"error_message_base64":"'"$(base64 --wrap=0 <<<"${error_message}")"'"'
    if [ "${THYCOTIC_CLI_CURL_ENABLE_VERBOSE}" = "${TRUE_STRING}" ]; then
      error_response+=',"curl_verbose_output_base64":"'"${thycotic_get_connection_manager_settings__curl_verbose_output_base64}"'"'
    fi
    error_response+='}'
    echo >&2 "${error_response}"
    return 101
  fi
  # If verbose output is enabled, also output the curl verbose output base64.
  if [ "${THYCOTIC_CLI_CURL_ENABLE_VERBOSE}" = "${TRUE_STRING}" ]; then
    echo >&2 '{"curl_verbose_output_base64":"'"${thycotic_authenticate__curl_verbose_output_base64}"'"}'
  fi
  return 0
}

get_thycotic_api_access_token()
{
  local error_message
  local error_response
  # Obtain a new access token.
  call_capture_stdout_and_stderr thycotic_authenticate
  thycotic_authenticate__rc="${catch_stdouterr__rc}"
  thycotic_authenticate__response_json="${catch_stdouterr__stdout}"
  thycotic_authenticate__curl_full_json_stderr="${catch_stdouterr__stderr}"
  # Get the curl information json value.
  call_capture_stdout_and_stderr get_json_element_value .curl_information_json thycotic_authenticate__curl_full_json_stderr
  if [ "${catch_stdouterr__rc}" -gt 0 ]; then
    error_message+="/-----------------------------------------------------------"$'\n'
    error_message+="Error: Failed to obtain an access token."$'\n'
    error_message+="Message UUID: 3b7fb59e-fae0-4a77-848f-d511be3671f3"$'\n'
    error_message+="Failed to get the curl_information_json value from the curl stderr."$'\n'
    error_message+="get_json_element_value return code: ${catch_stdouterr__rc}"$'\n'
    error_message+="get_json_element_value error message: ${catch_stdouterr__stderr}"$'\n'
    error_message+="The thycotic_authenticate stderr:"$'\n'
    error_message+="${thycotic_authenticate__curl_full_json_stderr}"$'\n'
    error_message+="\-----------------------------------------------------------"$'\n'
    error_response='{'
    error_response+='"error_message_base64":"'"$(base64 --wrap=0 <<<"${error_message}")"'"'
    error_response+='}'
    echo >&2 "${error_response}"
    return 15
  fi
  thycotic_authenticate__curl_information_json="${catch_stdouterr__stdout}"
  # Get the curl verbose output.
  call_capture_stdout_and_stderr get_json_element_value .curl_verbose_output_base64 thycotic_authenticate__curl_full_json_stderr
  if [ "${catch_stdouterr__rc}" -gt 0 ]; then
    error_message+="/-----------------------------------------------------------"$'\n'
    error_message+="Error: Failed to obtain an access token."$'\n'
    error_message+="Message UUID: ea7cc439-17f8-4ef2-8682-24140af9bd60"$'\n'
    error_message+="Failed to get the curl_verbose_output_base64 value from the curl stderr."$'\n'
    error_message+="get_json_element_value return code: ${catch_stdouterr__rc}"$'\n'
    error_message+="get_json_element_value error message: ${catch_stdouterr__stderr}"$'\n'
    error_message+="The thycotic_authenticate stderr:"$'\n'
    error_message+="${thycotic_authenticate__curl_full_json_stderr}"$'\n'
    error_message+="\-----------------------------------------------------------"$'\n'
    error_response='{'
    error_response+='"error_message_base64":"'"$(base64 --wrap=0 <<<"${error_message}")"'"'
    error_response+='}'
    echo >&2 "${error_response}"
    return 16
  fi
  thycotic_authenticate__curl_verbose_output_base64="${catch_stdouterr__stdout}"
  # Check that the thycotic authenticate call succeeded.
  if [ "${thycotic_authenticate__rc}" -gt 0 ]; then
    error_message+="/-----------------------------------------------------------"$'\n'
    error_message+="Error: Failed to obtain an access token."$'\n'
    error_message+="Message UUID: 64dd1032-b73f-441f-bfa0-f6c5fadece15"$'\n'
    error_message+="The curl command to authenticate to Thycotic failed with return code: ${thycotic_authenticate__rc}"$'\n'
    call_capture_stdout_and_stderr get_json_element_value .errormsg thycotic_authenticate__curl_information_json
    if [ "${catch_stdouterr__rc}" -gt 0 ]; then
      error_message+="Failed to get the error message (errormsg element) from the curl information JSON."$'\n'
      error_message+="get_json_element_value return code: ${catch_stdouterr__rc}"$'\n'
      error_message+="get_json_element_value error message: ${catch_stdouterr__stderr}"$'\n'
      error_message+="The curl command error output is:"$'\n'
      error_message+="${thycotic_authenticate__curl_full_json_stderr}"$'\n'
    else
      error_message+="The curl error message: ${catch_stdouterr__stdout}"$'\n'
    fi
    error_message+="\-----------------------------------------------------------"$'\n'
    error_response='{'
    error_response+='"error_message_base64":"'"$(base64 --wrap=0 <<<"${error_message}")"'"'
    error_response+='}'
    echo >&2 -n "${error_response}"
    return 17
  fi
  # Check that the HTTP status is 200
  call_capture_stdout_and_stderr get_http_code_from_curl_information_json thycotic_authenticate__curl_information_json
  if [ "${catch_stdouterr__rc}" -gt 0 ]; then
    error_message+="/-----------------------------------------------------------"$'\n'
    error_message+="Error: Failed to obtain an access token."$'\n'
    error_message+="Message UUID: 6501f01c-1007-44f9-851e-1a803aab2b09"$'\n'
    error_message+="Failed to get the HTTP status code (http_code element) from the curl information JSON."$'\n'
    error_message+="get_http_code_from_curl_information_json return code: ${catch_stdouterr__rc}"$'\n'
    error_message+="get_http_code_from_curl_information_json error message: ${catch_stdouterr__stderr}"$'\n'
    error_message+="The curl information JSON is:"$'\n'
    error_message+="${thycotic_authenticate__curl_information_json}"$'\n'
    error_message+="\-----------------------------------------------------------"$'\n'
    error_response='{'
    error_response+='"error_message_base64":"'"$(base64 --wrap=0 <<<"${error_message}")"'"'
    error_response+='}'
    echo >&2 "${error_response}"
    return 18
  fi
  curl__http_code="${catch_stdouterr__stdout}"
  if [ "${curl__http_code}" != "200" ]; then
    error_message+="/-----------------------------------------------------------"$'\n'
    error_message+="Error: Failed to obtain an access token."$'\n'
    error_message+="Message UUID: 74a75572-692f-4e08-99eb-680763aadec0"$'\n'
    error_message+="The HTTP status code for the authentication to Thycotic was: ${curl__http_code}  (expected 200)."$'\n'
    call_capture_stdout_and_stderr get_json_element_value .error thycotic_authenticate__response_json
    if [ "${catch_stdouterr__rc}" -gt 0 ]; then
      error_message+="Failed to get the error message (error element) from the Thycotic authenticate response JSON."$'\n'
      error_message+="Thycotic authenticate response JSON:"$'\n'
      error_message+="${thycotic_authenticate__response_json}"$'\n'
    else
      error_message+="Thycotic authenticate error message: ${catch_stdouterr__stdout}"$'\n'
    fi
    error_message+="\-----------------------------------------------------------"$'\n'
    error_response='{'
    error_response+='"error_message_base64":"'"$(base64 --wrap=0 <<<"${error_message}")"'"'
    if [ "${THYCOTIC_CLI_CURL_ENABLE_VERBOSE}" = "${TRUE_STRING}" ]; then
      error_response+=',"curl_verbose_output_base64":"'"${thycotic_authenticate__curl_verbose_output_base64}"'"'
    fi
    error_response+='}'
    echo >&2 "${error_response}"
    return 19
  fi
  # response is 200 OK
  # The check to ensure that the content_type is application/json is left out as the getting of
  # the access_token will either pass or fail depending on if the response is JSON or not.
  call_capture_stdout_and_stderr get_json_element_value .access_token thycotic_authenticate__response_json
  if [ "${catch_stdouterr__rc}" -ne 0 ]; then
    error_message+="/-----------------------------------------------------------"$'\n'
    error_message+="Error: Failed to obtain an access token."$'\n'
    error_message+="Message UUID: 66159660-5153-4a5c-b176-c50be01f68e6"$'\n'
    error_message+="Failed to get the Access Token (access_token element) from the Thycotic authenticate response JSON."$'\n'
    error_message+="get_json_element_value return code: ${catch_stdouterr__rc}"$'\n'
    error_message+="get_json_element_value error message: ${catch_stdouterr__stderr}"$'\n'
    error_message+="Thycotic authenticate response JSON:"$'\n'
    error_message+="${thycotic_authenticate__response_json}"$'\n'
    error_message+="\-----------------------------------------------------------"$'\n'
    error_response='{'
    error_response+='"error_message_base64":"'"$(base64 --wrap=0 <<<"${error_message}")"'"'
    error_response+='}'
    echo >&2 "${error_response}"
    return 20
  fi
  # If verbose output is enabled, also output the curl verbose output base64.
  if [ "${THYCOTIC_CLI_CURL_ENABLE_VERBOSE}" = "${TRUE_STRING}" ]; then
    echo >&2 '{"curl_verbose_output_base64":"'"${thycotic_authenticate__curl_verbose_output_base64}"'"}'
  fi
  echo "${catch_stdouterr__stdout}"
}

get_user_username()
{
  THYCOTIC_USER_USERNAME=""
  if [ -n "${THYCOTIC_CLI_GET_USERNAME_COMMAND}" ]; then
    call_capture_stdout_and_stderr eval "${THYCOTIC_CLI_GET_USERNAME_COMMAND}"
    if [ "${catch_stdouterr__rc}" -ne 0 ]; then
      echo >&2 "/-----------------------------------------------------------"
      echo >&2 "Warning: The command contained in THYCOTIC_CLI_GET_USERNAME_COMMAND failed and won't be used."
      echo >&2 "Command return code was: ${catch_stdouterr__rc}"
      echo >&2 "Command error message: ${catch_stdouterr__stderr}"
      echo >&2 "\-----------------------------------------------------------"
      THYCOTIC_USER_USERNAME=""
    else
      THYCOTIC_USER_USERNAME="${catch_stdouterr__stdout}"
    fi
  fi
  if [ -z "${THYCOTIC_USER_USERNAME}" ]; then
    # Prompt for username...
    THYCOTIC_USER_USERNAME_DEFAULT="${THYCOTIC_CLI_USERNAME:-${USER}}"
    echo >&2 -n "Thycotic - Please enter your Username [$THYCOTIC_USER_USERNAME_DEFAULT]: "
    read -r THYCOTIC_USER_USERNAME
    THYCOTIC_USER_USERNAME="${THYCOTIC_USER_USERNAME:-$THYCOTIC_USER_USERNAME_DEFAULT}"
  fi
}

get_user_password()
{
  THYCOTIC_USER_PASSWORD=""
  if [ -n "${THYCOTIC_CLI_GET_PASSWORD_COMMAND}" ]; then
    call_capture_stdout_and_stderr eval "${THYCOTIC_CLI_GET_PASSWORD_COMMAND}"
    if [ "${catch_stdouterr__rc}" -ne 0 ]; then
      echo >&2 "/-----------------------------------------------------------"
      echo >&2 "Warning: The command contained in THYCOTIC_CLI_GET_PASSWORD_COMMAND failed and won't be used."
      echo >&2 "Command return code was: ${catch_stdouterr__rc}"
      echo >&2 "Command error message: ${catch_stdouterr__stderr}"
      echo >&2 "\-----------------------------------------------------------"
      THYCOTIC_USER_PASSWORD=""
    else
      THYCOTIC_USER_PASSWORD="${catch_stdouterr__stdout}"
    fi
  fi
  if [ -z "${THYCOTIC_USER_PASSWORD}" ]; then
    # Prompt for password...
    echo >&2 -n "Thycotic - Please enter the Password for user $THYCOTIC_USER_USERNAME: "
    read -sr THYCOTIC_USER_PASSWORD
    echo >&2
  fi
}

get_http_code_from_curl_information_json()
  # Parameters:
  #   ${1}  - the name of the variable that contains the curl information JSON
  # Error return codes:
  #   1  - if parameter 1 does not have a value
  #   3  - if the http_code element could not be obtained from the curl information JSON
  #   4  - if the http_code element does not have a value
{
  if [ -z "${1}" ]; then
    echo >&2 "Error in get_http_code_from_curl_information_json - parameter 1 does not have a value"
    return 1
  fi
  call_capture_stdout_and_stderr get_json_element_value .http_code "${1}"
  if [ "${catch_stdouterr__rc}" -gt 0 ]; then
    echo >&2 "Error in get_http_code_from_curl_information_json - failed to get .http_code from curl information json."
    echo >&2 "get_json_element_value return code: ${catch_stdouterr__rc}"
    echo >&2 "get_json_element_value error message: ${catch_stdouterr__stderr}"
    echo >&2 "The curl information json provided (named ${1}) was:"
    echo >&2 "-------------------------------------"
    echo >&2 "${!1}"
    echo >&2 "-------------------------------------"
    return 3
  fi
  http_code="${catch_stdouterr__stdout}"
  if [ -z "${http_code}" ]; then
    echo >&2 "Error in get_http_code_from_curl_information_json - the http_code from the curl information json was empty."
    echo >&2 "The curl information json provided (named ${1}) was:"
    echo >&2 "-------------------------------------"
    echo >&2 "${!1}"
    echo >&2 "-------------------------------------"
    return 4
  fi
  echo "${http_code}"
  return 0
}

get_json_element_value()
  # Return the value of the named element from the given JSON
  # Parameters:
  #   ${1}  - the key of the element to get
  #   ${2}  - the name of the variable that contains the JSON
  # Error return codes:
  #   1  - if parameter 1 does not have a value
  #   2  - if parameter 2 does not have a value
  #   3  - if the jq command to determine if the element exists fails
  #   4  - if the element does not exist or is null
  #   5  - if the jq command to get the value of the element fails
{
  if [ -z "${1}" ]; then
    echo >&2 "Error in get_json_element_value - parameter 1 does not have a value"
    return 1
  fi
  if [ -z "${2}" ]; then
    echo >&2 "Error in get_json_element_value - parameter 2 does not have a value"
    return 2
  fi
  jq_has_result="$(jq 'if '"${1}"' == null then false else true end' < <(echo "${!2}"))"
  jq_return_code1="$?"
  if [ "${jq_return_code1}" -gt 0 ]; then
    return 3
  else
    if [ "${jq_has_result}" == "false" ]; then
      echo >&2 "Element ${1} does not exist or is null"
      echo >&2 "The json provided (named ${2}) was:"
      echo >&2 "-------------------------------------"
      echo >&2 "${!2}"
      echo >&2 "-------------------------------------"
      return 4
    else
      element_value="$(jq -r "${1}" < <(echo -n "${!2}"))"
      jq_return_code2="$?"
      if [ "${jq_return_code2}" -gt 0 ]; then
        echo >&2 "An error occurred getting element ${1} from the json."
        echo >&2 "The json provided (named ${2}) was:"
        echo >&2 "-------------------------------------"
        echo >&2 "${!2}"
        echo >&2 "-------------------------------------"
        return 5
      else
        echo -n "${element_value}"
        return 0
      fi
    fi
  fi
}

call_curl_and_prepare_response()
  # Call the given curl command and prepare the response values that includes the stderr response json structure that contains both the verbose output lines and the curl_information_json value.
  # Parameters:
  #   ${1}  - the name of the curl function to call
{
  local curl__stdout
  local curl__stderr
  capture_stdout_and_stderr curl__stdout curl__stderr "${1}"
  curl__rc="${?}"
  curl_verbose_lines="$(echo -n "${curl__stderr}" | grep --invert-match "___CURL_OUTPUT___")"
  curl_information_json_line="$(echo -n "${curl__stderr}" | grep "___CURL_OUTPUT___CURL_INFORMATION_JSON___" | sed 's/___CURL_OUTPUT___CURL_INFORMATION_JSON___//g')"
  curl_full_json="$(echo -n '{"curl_verbose_output_base64":"'"$(echo -n "${curl_verbose_lines}" | base64 --wrap=0)"'","curl_information_json":'"${curl_information_json_line}"'}')"
  echo -n "${curl__stdout}"
  echo >&2 -n "${curl_full_json}"
  return "${curl__rc}"
}

thycotic_authenticate()
{
  local curl__stdout
  local curl__stderr
  capture_stdout_and_stderr curl__stdout curl__stderr call_curl_and_prepare_response thycotic_authenticate_curl_command
  curl__rc="${?}"
  echo -n "${curl__stdout}"
  echo >&2 -n "${curl__stderr}"
  return "${curl__rc}"
}

thycotic_get_secret()
{
  local curl__stdout
  local curl__stderr
  capture_stdout_and_stderr curl__stdout curl__stderr call_curl_and_prepare_response thycotic_get_secret_curl_command
  curl__rc="${?}"
  echo -n "${curl__stdout}"
  echo >&2 -n "${curl__stderr}"
  return "${curl__rc}"
}

thycotic_get_secret_field()
{
  local curl__stdout
  local curl__stderr
  capture_stdout_and_stderr curl__stdout curl__stderr call_curl_and_prepare_response thycotic_get_secret_field_curl_command
  curl__rc="${?}"
  echo -n "${curl__stdout}"
  echo >&2 -n "${curl__stderr}"
  return "${curl__rc}"
}

thycotic_get_connection_manager_settings()
{
  local curl__stdout
  local curl__stderr
  capture_stdout_and_stderr curl__stdout curl__stderr call_curl_and_prepare_response thycotic_get_connection_manager_settings_curl_command
  curl__rc="${?}"
  echo -n "${curl__stdout}"
  echo >&2 -n "${curl__stderr}"
  return "${curl__rc}"
}

thycotic_authenticate_curl_command()
  # See:
  # https://thycotic.ad.adelaide.edu.au/RestApiDocs.ashx?doc=oauth-help#tag/Authentication/operation/OAuth2Service_Authorize
{
  curl \
      --silent \
      ${THYCOTIC_CLI_CURL_ENABLE_VERBOSE:+"--verbose"} \
      --write-out "%{stderr}___CURL_OUTPUT___CURL_INFORMATION_JSON___%{json}" \
      --header "Content-Type: application/x-www-form-urlencoded" \
      --data @- \
      --url "${THYCOTIC_CLI_THYCOTIC_HOST_URL}/oauth2/token" < <(echo -n "grant_type=password&username=${THYCOTIC_USER_USERNAME}&password=${THYCOTIC_USER_PASSWORD}&organization=&domain=uofa")
}

thycotic_get_secret_curl_command()
  # See:
  # https://thycotic.ad.adelaide.edu.au/RestApiDocs.ashx?doc=Secrets#tag/Secrets/operation/SecretsService_GetSecretV2
{
  curl \
      --silent \
      ${THYCOTIC_CLI_CURL_ENABLE_VERBOSE:+"--verbose"} \
      --write-out "%{stderr}___CURL_OUTPUT___CURL_INFORMATION_JSON___%{json}" \
      --header "Authorization: Bearer ${THYCOTIC_CLI_THYCOTIC_API_ACCESS_TOKEN}" \
      --url "${THYCOTIC_CLI_THYCOTIC_HOST_URL}/api/v2/secrets/${THYCOTIC_CLI_SECRET_ID}"
}

thycotic_get_secret_field_curl_command()
  # See:
  # https://thycotic.ad.adelaide.edu.au/RestApiDocs.ashx?doc=Secrets#tag/Secrets/operation/SecretsService_GetField
{
  curl \
      --silent \
      ${THYCOTIC_CLI_CURL_ENABLE_VERBOSE:+"--verbose"} \
      --write-out "%{stderr}___CURL_OUTPUT___CURL_INFORMATION_JSON___%{json}" \
      --header "Authorization: Bearer ${THYCOTIC_CLI_THYCOTIC_API_ACCESS_TOKEN}" \
      --url "${THYCOTIC_CLI_THYCOTIC_HOST_URL}/api/v1/secrets/${THYCOTIC_CLI_SECRET_ID}/fields/${THYCOTIC_CLI_SECRET_FIELD_SLUG}"
}

thycotic_get_connection_manager_settings_curl_command()
  # See:
  # https://thycotic.ad.adelaide.edu.au/RestApiDocs.ashx?doc=ConnectionManagerSettings#tag/ConnectionManagerSettings/operation/ConnectionManagerSettingsService_Get
{
  curl \
      --silent \
      ${THYCOTIC_CLI_CURL_ENABLE_VERBOSE:+"--verbose"} \
      --write-out "%{stderr}___CURL_OUTPUT___CURL_INFORMATION_JSON___%{json}" \
      --header "Authorization: Bearer ${THYCOTIC_CLI_THYCOTIC_API_ACCESS_TOKEN}" \
      --url "${THYCOTIC_CLI_THYCOTIC_HOST_URL}/api/v1/connection-manager-settings"
}

parse_script_params()
  # Parse the parameters and up until a thycotic_cli command (the first parameter that does not start with a hyphen).
  # Return codes:
  #   0   - parsing succeeded
  #   1   - an error occurred; an unknown parameter was provided or one of the required parameters was not provided or the thycotic_cli command was not provided
  #   101 - one of --help or --version was given and the program can exit
{
  #echo >&2 "script params (${#}) are: ${*}"
  # default values of variables set from params
  SCRIPT_DEBUG_OPTION="${FALSE_STRING}"
  THYCOTIC_CLI_COMMAND=""
  while [ "${#}" -gt 0 ]
  do
    case "${1-}" in
      --help | -h)
        usage
        return 10
        ;;
      --script_debug)
        SCRIPT_DEBUG_OPTION="${TRUE_STRING}"
        ;;
      --version)
        print_version_info
        return 10
        ;;
      --thycotic_host_url=*)
        THYCOTIC_CLI_THYCOTIC_HOST_URL="${1#*=}"
        ;;
      --access_token=*)
        THYCOTIC_CLI_THYCOTIC_API_ACCESS_TOKEN="${1#*=}"
        ;;
      -?*)
        echo >&2 "Error: Unknown parameter: ${1}"
        echo >&2 "Use --help for usage help"
        return 1
        ;;
      *)
        THYCOTIC_CLI_COMMAND="${1-}"
        break
        ;;
    esac
    shift
  done
  if [ -z "${THYCOTIC_CLI_THYCOTIC_HOST_URL}" ]; then
    echo >&2 "Error: Missing required parameter: thycotic_host_url"
    echo >&2 "Use --help for usage help"
    return 1
  fi
  if [ -z "${THYCOTIC_CLI_COMMAND}" ]; then
    echo >&2 "Error: Missing required argument: command"
    echo >&2 "Use --help for usage help"
    return 1
  fi
}

parse_script_params_get_secret()
{
  #echo >&2 "script params (get_secret) (${#}) are: ${*}"
  # default values of variables set from params
  THYCOTIC_CLI_SECRET_ID=""
  while [ "${#}" -gt 0 ]
  do
    case "${1-}" in
      get_secret)
        shift
        break
        ;;
    esac
    shift
  done
  while [ "${#}" -gt 0 ]
  do
    case "${1-}" in
      --secret_id=*)
        THYCOTIC_CLI_SECRET_ID="${1#*=}"
        ;;
      --help | -h)
        usage_get_secret
        exit
        ;;
      -?*)
        echo >&2 "Error: Unknown get_secret parameter: ${1}"
        echo >&2 "Use --help for usage help"
        return 1
        ;;
    esac
    shift
  done
  if [ -z "${THYCOTIC_CLI_SECRET_ID}" ]; then
    echo >&2 "Error: Missing required parameter: secret_id"
    return 1
  fi
  #echo >&2 "THYCOTIC_CLI_SECRET_ID: ${THYCOTIC_CLI_SECRET_ID}"
}

parse_script_params_get_secret_field_value()
{
  #echo >&2 "script params (get_secret_field_value) (${#}) are: ${*}"
  # default values of variables set from params
  THYCOTIC_CLI_SECRET_ID=""
  THYCOTIC_CLI_SECRET_FIELD_SLUG=""
  while [ "${#}" -gt 0 ]
  do
    case "${1-}" in
      get_secret_field_value)
        shift
        break
        ;;
    esac
    shift
  done
  while [ "${#}" -gt 0 ]
  do
    case "${1-}" in
      --secret_id=*)
        THYCOTIC_CLI_SECRET_ID="${1#*=}"
        ;;
      --field_slug=*)
        THYCOTIC_CLI_SECRET_FIELD_SLUG="${1#*=}"
        ;;
      --help | -h)
        usage_get_secret_field_value
        exit
        ;;
      -?*)
        echo >&2 "Error: Unknown get_secret_field_value parameter: ${1}"
        echo >&2 "Use --help for usage help"
        return 1
        ;;
    esac
    shift
  done
  if [ -z "${THYCOTIC_CLI_SECRET_ID}" ]; then
    echo >&2 "Error: Missing required parameter: secret_id"
    return 1
  fi
  if [ -z "${THYCOTIC_CLI_SECRET_FIELD_SLUG}" ]; then
    echo >&2 "Error: Missing required parameter: field_slug"
    return 1
  fi
  #echo >&2 "THYCOTIC_CLI_SECRET_ID: ${THYCOTIC_CLI_SECRET_ID}"
  #echo >&2 "THYCOTIC_CLI_SECRET_FIELD_SLUG: ${THYCOTIC_CLI_SECRET_FIELD_SLUG}"
}

parse_script_params_authenticate()
{
  #echo >&2 "script params (authenticate) (${#}) are: ${*}"
  # default values of variables set from params
  while [ "${#}" -gt 0 ]
  do
    case "${1-}" in
      authenticate)
        shift
        break
        ;;
    esac
    shift
  done
  while [ "${#}" -gt 0 ]
  do
    case "${1-}" in
      --help | -h)
        usage_authenticate
        exit
        ;;
      -?*)
        echo >&2 "Error: Unknown authenticate parameter: ${1}"
        echo >&2 "Use --help for usage help"
        return 1
        ;;
    esac
    shift
  done
}

print_version_info()
{
  echo "thycotic_cli version 0.8.0"
}

call_capture_stdout_and_stderr()
  # Calls catch_stdouterr to call the function named in the first parameter.
  # Result variables:
  #   - catch_stdouterr__rc       - the return code from the function call
  #   - catch_stdouterr__stdout   - the stdout from the function call
  #   - catch_stdouterr__stderr   - the stderr from the function call
{
  capture_stdout_and_stderr catch_stdouterr__stdout catch_stdouterr__stderr "${@}"
  catch_stdouterr__rc="$?"
  return "${catch_stdouterr__rc}"
}

initialize()
{
  set -o pipefail
  THIS_SCRIPT_PROCESS_ID=$$
  initialize_abort_script_config
  initialize_this_script_directory_variable
  initialize_this_script_name_variable
  initialize_true_and_false_strings
  initialize_function_capture_stdout_and_stderr
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
    echo >&2 "Error: Failed to determine the value of this_script_directory. ${THIS_SCRIPT_DIRECTORY}"
    abort_script
  fi
}

initialize_this_script_name_variable()
{
  local path_to_invoked_script
  local default_script_name
  path_to_invoked_script="${BASH_SOURCE[0]}"
  default_script_name="default_script_name_value"
  if grep -q '/dev/fd' <(dirname "${path_to_invoked_script}"); then
    # The script was invoked via process substitution
    if [ -z "${default_script_name}" ]; then
      THIS_SCRIPT_NAME="<script invoked via file descriptor (process substitution) and no default script name set>"
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

initialize_function_capture_stdout_and_stderr()
{
  local capture_stdout_and_stderr_script_path
  capture_stdout_and_stderr_script_path="/usr/local/bin/capture_stdout_and_stderr.sh"
  if [ -f "${capture_stdout_and_stderr_script_path}" ]; then
    # shellcheck source=/usr/local/bin/capture_stdout_and_stderr.sh
    . "${capture_stdout_and_stderr_script_path}"
  else
    echo >&2 "[ERROR] capture_stdout_and_stderr script file was not found (${capture_stdout_and_stderr_script_path})."
    abort_script
  fi
}

initialize_abort_script_config()
{
  # Exit shell script from within the script or from any subshell within this script - adapted from:
  # https://cravencode.com/post/essentials/exit-shell-script-from-subshell/
  # Exit with exit status 1 if this (top level process of this script) receives the SIGUSR1 signal.
  # See also the abort_script() function which sends the signal.
  trap "exit 1" SIGUSR1
}

abort_script()
{
  echo >&2 "${THIS_SCRIPT_NAME} - aborting..."
  echo >&2 "THIS_SCRIPT_NAME is >${THIS_SCRIPT_NAME}<"
  echo >&2 "THIS_SCRIPT_PROCESS_ID is >${THIS_SCRIPT_PROCESS_ID}<"
  kill -SIGUSR1 ${THIS_SCRIPT_PROCESS_ID}
  exit
}

# shellspec
# Return from script here if it is being sourced by shellspec.
# See: https://github.com/shellspec/shellspec?tab=readme-ov-file#__sourced__
${__SOURCED__:+return}

# Main entry into the script - call the main() function
main "${@}"
