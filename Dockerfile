FROM       hasufell/exherbo:latest
MAINTAINER Julian Ospald <hasufell@posteo.de>


COPY ./config/paludis /etc/paludis


##### PACKAGE INSTALLATION #####

# update world with our options
RUN chgrp paludisbuild /dev/tty && \
	eclectic env update && \
	source /etc/profile && \
	cave sync && \
	cave resolve -z -1 repository/net -x && \
	cave resolve -z -1 repository/hasufell -x && \
	cave resolve -z -1 repository/python -x && \
	cave resolve -c modsecurity -x && \
	git clone https://github.com/SpiderLabs/ModSecurity.git /usr/src/modsecurity && \
	cd /usr/src/modsecurity && \
	./autogen.sh && \
	./configure --enable-standalone-module --disable-mlogc && \
	make && \
	cave update-world -s nginx && \
	cave resolve -c world -x -f --permit-old-version '*/*' && \
	cave resolve -c world -x --permit-old-version '*/*' && \
	cave purge -x && \
	cave fix-linkage -x && \
	rm -rf /usr/portage/distfiles/*

RUN eclectic config accept-all


################################

# copy nginx config
COPY ./config/nginx.conf /etc/nginx/nginx.conf
COPY ./config/sites-enabled /etc/nginx/sites-enabled
COPY ./config/sites-available /etc/nginx/sites-available

# set up modescurity
RUN mkdir /etc/nginx/modsecurity && \
	cp /usr/src/modsecurity/modsecurity.conf-recommended \
		/etc/nginx/modsecurity/modsecurity.conf && \
	sed -i \
		-e 's|SecRuleEngine .*$|SecRuleEngine On|' \
		/etc/nginx/modsecurity/modsecurity.conf && \
	cp /etc/nginx/modsecurity/modsecurity.conf \
		/etc/nginx/modsecurity/modsecurity.conf.orig && \
	cp /usr/src/modsecurity/unicode.mapping /etc/nginx/modsecurity/
RUN git clone --depth=1 https://github.com/SpiderLabs/owasp-modsecurity-crs.git \
	/etc/modsecurity
RUN cat /etc/modsecurity/base_rules/*.conf >> \
	/etc/nginx/modsecurity/modsecurity.conf && \
	cp /etc/modsecurity/base_rules/*.data /etc/nginx/modsecurity/
COPY ./config/update-modsec.sh /usr/bin/update-modsec.sh
RUN chmod +x /usr/bin/update-modsec.sh

# supervisor config
COPY ./config/supervisord.conf /etc/supervisord.conf

# web server
EXPOSE 80 443

# create common group to be able to synchronize permissions to shared data volumes
RUN groupadd -g 777 www

# create missing tmp folder
RUN mkdir /tmp/nginx

CMD exec /usr/bin/supervisord -n -c /etc/supervisord.conf

