## Godaddy.sh

This script is a hook for [dehydrated](https://github.com/lukas2511/dehydrated) which uses the [Godaddy
API](https://developer.godaddy.com/doc#!/_v1_domains) to obtain
SSL certificates using dns-01 domain ownership verification.

This script has one optional dependency: dig.

Without dig installed, a three minute delay occurs for each
domain name.  If dig is installed, the scripts waits for tokens
to propagate to the nameservers, which is generally faster.

If you have a Godaddy account, you can obtain a Godaddy API key
and secret by visiting: https://developer.godaddy.com/keys/

## Usage:

Given your Godaddy API key and secret, insert them the bash
shell commands as follows:

``` text
export PROVIDER=godaddy
export GD_KEY="your-godaddy-api-key-here"
export GD_SECRET="your-godaddy-api-secret-here"
echo "foo.com" >>domains.txt
dehydrated --challenge dns-01 --hook godaddy.sh
```

## Resources:
+ dehydrated: https://github.com/lukas2511/dehydrated
+ a similar godaddy hook: https://github.com/josteink/le-godaddy-dns
+ Godaddy API documentation: https://developer.godaddy.com/doc#!/_v1_domains
+ Godaddy API keys: https://developer.godaddy.com/keys/
