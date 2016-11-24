## Godaddy.sh

This script is a hook for [dehydrated](https://github.com/lukas2511/dehydrated) which uses the [Godaddy
API](https://developer.godaddy.com/doc#!/_v1_domains) to obtain
SSL certificates using dns-01 domain ownership verification.

This script has one optional dependency: dig.

You don't have to have dig installed, but this will run faster
if dig is installed.  Without dig, a three minute delay occurs
for each domain name.  With dig installed, the scripts waits for
tokens to propagate to the nameservers, which is faster.

If you have a Godaddy account, you can obtain a Godaddy API key
and secret by visiting: https://developer.godaddy.com/keys/

### Install:

``` text
# install letsencrypt.sh dependencies
sudo apt-get install -y openssl curl sed grep mktemp git
# install optional godaddy.sh dependency
sudo apt-get install -y dig
# install letsencrypt.sh
git clone https://github.com/lukas2511/dehydrated.git
cd dehydrated
curl -O https://raw.githubusercontent.com/zxvv/dehydrated-godaddy-dns-01/master/godaddy.sh
```

### Usage:

Given your Godaddy API key and secret, insert them the bash
shell commands as follows:

``` text
export PROVIDER=godaddy
export GD_KEY="your-godaddy-api-key-here"
export GD_SECRET="your-godaddy-api-secret-here"
echo "foo.com" >domains.txt
./dehydrated --challenge dns-01 --hook godaddy.sh
```
### Caveats:

In certain cases, a fixed delay of three minutes may be
insufficient, resulting in failure.  The fixed delay can be
altered by setting DNS_UPDATE_DELAY.  The following example sets
the delay to ten minutes:

``` text
export DNS_UPDATE_DELAY 600
```

Due to limitations of the Godaddy API, it is not feasible for
this hook to remove the "_acme-challenge" TXT records from the
DNS zone file, unless it imposed additional installation
dependencies.  For this reason, during cleanup, this script sets
the TXT value of the "_acme-challenge" records to "delete-me",
to identify them for later cleanup.




### Resources:
+ dehydrated: https://github.com/lukas2511/dehydrated
+ How to install dehydrated: http://blog.thesparktree.com/post/138999997429/generating-intranet-and-private-network-ssl
+ Another godaddy API hook: https://github.com/josteink/le-godaddy-dns
+ Godaddy API documentation: https://developer.godaddy.com/doc#!/_v1_domains
+ Godaddy API keys: https://developer.godaddy.com/keys/
