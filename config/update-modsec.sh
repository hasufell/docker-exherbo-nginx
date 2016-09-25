#!/bin/bash

echoerr() { cat <<< "$@" 1>&2; }

die() {
	echoerr "${@:-Something went wrong!}"
	exit 1
}

if [[ -e /etc/nginx/modsecurity/modsecurity.conf.orig ]] ; then
	while true; do
		if [[ $(date +%H) == 23 ]] ; then
			cd /etc/modsecurity || die
			git pull origin master || die
			cat /etc/nginx/modsecurity/modsecurity.conf.orig \
				> /etc/nginx/modsecurity/modsecurity.conf || die
			cat /etc/modsecurity/base_rules/*.conf \
				>> /etc/nginx/modsecurity/modsecurity.conf || die
			rm /etc/nginx/modsecurity/*.data || die
			cp /etc/modsecurity/base_rules/*.data /etc/nginx/modsecurity/ \
				|| die
			nginx -s reload || die
		fi
		sleep 1h
	done
else
	echoerr "This script requires the file /etc/nginx/modsecurity/modsecurity.conf.orig"
	echoerr "which has to be the base configuration without the rule-set."
fi
