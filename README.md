# Godaddy.sh

This script is a hook for dehydrated
(https://github.com/lukas2511/dehydrated) which uses the Godaddy
API to perform dns-01 domain ownership validation.

This script has one optional dependency: dig.

Without dig installed, a three minutes delay occurs for each
domain name.  If dig is installed, the delay is only as long as
it takes the tokens to propagate to the nameservers.

To obtain certificates using this script, one needs
a godaddy API key and corresponding secret, which can be
obtained by visiting: (https://developer.godaddy.com/keys/)

Given a godaddy API key and secret, insert them the bash
shell commands as follwos:

## Usage:

'''export PROVIDER=godaddy
export GD_KEY="your-godaddy-api-key-here"
export GD_SECRET="your-godaddy-api-secret-here"
dehydrated --challenge dns-01 --cron --hook godaddy.sh
'''
