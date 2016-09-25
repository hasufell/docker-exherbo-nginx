#!/bin/bash

if [[ "${CATEGORY}/${PN}" == "www-servers/nginx" ]] ; then
	einfo "hacking configure script"
	mv "${WORK}"/configure "${WORK}"/configure.real
	cat > "${WORK}"/configure <<EOF
#!/bin/bash
./configure.real --add-module=/usr/src/modsecurity/nginx/modsecurity "\$@"
EOF
	chmod +x "${WORK}"/configure

fi

