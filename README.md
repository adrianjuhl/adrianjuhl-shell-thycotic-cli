# thycotic_cli

A script that facilitates interacting with Thycotic and providing the ability for getting secrets.

## Script usage

### Basic usage

**help**
```
$ thycotic_cli --help
```
Prints thycotic_cli help and usage information.

**get a secret field value**
```
$ thycotic_cli --thycotic_host_url=https://your-thycotic-server-hostname get_secret_field_value --secret_id=1234 --field_slug=password
```
Get the value of the given secret field.

**get a secret**
```
$ thycotic_cli --thycotic_host_url=https://your-thycotic-server-hostname get_secret --secret_id=1234
```
Get the given secret, printing out its JSON structure.

**authenticate**
```
$ thycotic_cli --thycotic_host_url=https://your-thycotic-server-hostname authenticate
```
Get an access token. The access token can be used in subsequent calls to thycotic_cli as an alternative to being prompted for credentials.

### Suggested usage

Add to .bashrc:
```
# Set default host for thycotic_cli:
export THYCOTIC_CLI_THYCOTIC_HOST_URL='https://your-thycotic-server-hostname'

# Set default username for thycotic_cli (useful if your thycotic username is different to your host machine username):
export THYCOTIC_CLI_USERNAME='your_thycotic_username'

# Alias for thycotic_cli authenticate, and save the access token:
alias thycotic_cli.authenticate='export THYCOTIC_CLI_THYCOTIC_API_ACCESS_TOKEN="$(thycotic_cli authenticate)"'
```

Then, getting secrets is as simple as:
```
# authenticate (which will only be needed again after the access token expires)
$ thycotic_cli.authenticate

# get a secret field value (call repeatedly as required)
$ thycotic_cli get_secret_field_value --secret_id=1234 --field_slug=password

# or get a secret entry (call repeatedly as required)
$ thycotic_cli get_secret --secret_id=1234
```

## Dependencies

thycotic_cli requires the following:
* curl
* jq
* [capture-stdout-and-stderr](https://github.com/adrianjuhl/adrianjuhl-shell-capture-stdout-and-stderr)

## License

MIT

## See also

To install this script using ansible, see the following ansible role:
- [adrianjuhl.thycotic_cli](https://galaxy.ansible.com/ui/standalone/roles/adrianjuhl/thycotic_cli/) (Ansible Galaxy)
- [adrianjuhl.ansible-role-thycotic-cli](https://github.com/adrianjuhl/ansible-role-thycotic-cli) (source code repository)

## Author Information

[Adrian Juhl](http://github.com/adrianjuhl)
