#!/usr/bin/env bash

#
# dns-01 challenge using the GoDaddy API.
# https://developer.godaddy.com/doc#!/_v1_domains

set -e
set -u
set -o pipefail

# Example use of this script:

# export PROVIDER=godaddy
# export GD_SECRET=8oQGNXJ1ZAPwZefs3RKTL8
# export GD_KEY=VVJ9uCG2_8oQBFAqUUx4uPn27Jw6ciG
# dehydrated --challenge dns-01 --cron --hook godaddy.sh

# visit https://developer.godaddy.com/keys/
# to get a godaddy API key and corresponding secret.

# This script requires curl and dig.

function deploy_challenge {
    local DOMAIN="${1}" TOKEN_FILENAME="${2}" TOKEN_VALUE="${3}"

    # note: the following code assumes that the parent domain has a
    # single name followed by top level domain, suuch as "foo.com".

    # Split DOMAIN into a record SUFFIX and a PARENT domain.
    # We prepend a '.' to SUBDOMAIN since we will append it to _acme-challenge
    # Otherwise the suffix is empty.

    # Why do we split them?  If we do not split out the subdomain, and
    # use it to specify a record name, the godaddy API may remove
    # *all* other TXT records for the domain.

    SUBDOMAIN="${DOMAIN%.*.*}"
    PARENT=${DOMAIN#$SUBDOMAIN.}
    if [[ ${PARENT} == $DOMAIN ]]; then
        SUBDOMAIN=""
    else
        SUBDOMAIN=".${SUBDOMAIN}"
    fi    
    echo " + deploy_challenge called: DOMAIN=${DOMAIN} SUBDOMAIN=${SUBDOMAIN} PARENT=${PARENT} TOKEN=${TOKEN_VALUE}"

    # create the TXT record containing the TOKEN_VALUE.

    curl -X PUT https://api.godaddy.com/v1/domains/${PARENT}/records/TXT/_acme-challenge${SUBDOMAIN} -H "Authorization: sso-key ${GD_KEY}:${GD_SECRET}" -H "Content-Type: application/json" -d "[{\"ttl\": 600, \"data\": \"${TOKEN_VALUE}\"}]"
    echo

    if command -v dig >/dev/null 2>&1 ;then
        # Wait until the TOKEN_VALUE appears on all of the nameservers for the domain.
        # This prints a dot (.) every second to show progress.
        
        # Why? Although Godaddy may update the DNS records in seconds
        # in some cases, delays of several minutes or more have been
        # consistenly observed.
        
        echo -n " + waiting for ${TOKEN_VALUE} in the _acme-challenge.${DOMAIN} TXT record on all nameservers:"
        NSLIST=$(dig +short NS ${PARENT})
        while true; do 
            DONE=1
            for NS in ${NSLIST}; do
                dig +noall +answer -t txt @$NS _acme-challenge.${DOMAIN}|grep -qe ${TOKEN_VALUE} || DONE=0
            done
            [[ ${DONE} == 1 ]] && break
            sleep 1                 # sleep until the token is present on the name server
            echo -n .
        done
        echo
    else
        echo " + dig is not installed, so we sleep for three minutes for tokens to appear in nameservers."
        echo " + Installing dig will reduce the wait duration."
        sleep ${DNS_UPDATE_DELAY:-180}
    fi

    # This hook is called once for every domain that needs to be
    # validated, including any alternative names you may have listed.
    #
    # Parameters:
    # - DOMAIN
    #   The domain name (CN or subject alternative name) being
    #   validated.
    # - TOKEN_FILENAME
    #   The name of the file containing the token to be served for HTTP
    #   validation. Should be served by your web server as
    #   /.well-known/acme-challenge/${TOKEN_FILENAME}.
    # - TOKEN_VALUE
    #   The token value that needs to be served for validation. For DNS
    #   validation, this is what you want to put in the _acme-challenge
    #   TXT record. For HTTP validation it is the value that is expected
    #   be found in the $TOKEN_FILENAME file.
}

function clean_challenge {
    local DOMAIN="${1}" TOKEN_FILENAME="${2}" TOKEN_VALUE="${3}"

    SUBDOMAIN="${DOMAIN%.*.*}"
    PARENT=${DOMAIN#$SUBDOMAIN.}
    if [[ ${PARENT} == $DOMAIN ]]; then
        SUBDOMAIN=""
    else
        SUBDOMAIN=".${SUBDOMAIN}"
    fi    
    echo " + deploy_challenge called: DOMAIN=${DOMAIN} SUBDOMAIN=${SUBDOMAIN} PARENT=${PARENT} TOKEN=${TOKEN_VALUE}"

    # Note: The following does not remove the corresponding TXT
    # records, because there appears to be no Godaddy API call that
    # will remove a single, specified TXT record; rather only a call
    # that will remove ALL TXT records, which may be undesirable.

    # I've tried the following, which each return:
    #     -d "": "Request body doesn't fulfill schema"
    #     -d "[]": Records must be specified.
    #     -d "[{}]": Request body doesn't fulfill schema.
    #     -d "[{\"data\":\"\"}]": One or more of the given records is invalid
    # Also, this api endpoint does not support DELETE.

    # So, lacking a way to deletie the record, this replaces the value
    # with "delete me", to assist the user in cleaning up later using
    # the web ui.

    curl -X PUT https://api.godaddy.com/v1/domains/${PARENT}/records/TXT/_acme-challenge${SUBDOMAIN} -H "Authorization: sso-key ${GD_KEY}:${GD_SECRET}" -H "Content-Type: application/json" -d "[{\"ttl\": 600, \"data\": \"delete me\"}]"
    echo

    # This hook is called after attempting to validate each domain,
    # whether or not validation was successful. Here you can delete
    # files or DNS records that are no longer needed.
    #
    # The parameters are the same as for deploy_challenge.
}

function deploy_cert {
    local DOMAIN="${1}" KEYFILE="${2}" CERTFILE="${3}" FULLCHAINFILE="${4}" CHAINFILE="${5}"

    echo "deploy_cert called: ${DOMAIN}, ${KEYFILE}, ${CERTFILE}, ${FULLCHAINFILE}, ${CHAINFILE}"

    # This hook is called once for each certificate that has been
    # produced. Here you might, for instance, copy your new certificates
    # to service-specific locations and reload the service.
    #
    # Parameters:
    # - DOMAIN
    #   The primary domain name, i.e. the certificate common
    #   name (CN).
    # - KEYFILE
    #   The path of the file containing the private key.
    # - CERTFILE
    #   The path of the file containing the signed certificate.
    # - FULLCHAINFILE
    #   The path of the file containing the full certificate chain.
    # - CHAINFILE
    #   The path of the file containing the intermediate certificate(s).
}

function unchanged_cert {
    local DOMAIN="${1}" KEYFILE="${2}" CERTFILE="${3}" FULLCHAINFILE="${4}" CHAINFILE="${5}"

    echo "unchanged_cert called: ${DOMAIN}, ${KEYFILE}, ${CERTFILE}, ${FULLCHAINFILE}, ${CHAINFILE}"

    # This hook is called once for each certificate that is still
    # valid and therefore wasn't reissued.
    #
    # Parameters:
    # - DOMAIN
    #   The primary domain name, i.e. the certificate common
    #   name (CN).
    # - KEYFILE
    #   The path of the file containing the private key.
    # - CERTFILE
    #   The path of the file containing the signed certificate.
    # - FULLCHAINFILE
    #   The path of the file containing the full certificate chain.
    # - CHAINFILE
    #   The path of the file containing the intermediate certificate(s).
}

HANDLER=$1; shift; $HANDLER "$@"
