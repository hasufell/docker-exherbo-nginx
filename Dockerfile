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

# supervisor config
COPY ./config/supervisord.conf /etc/supervisord.conf

# web server
EXPOSE 80 443

# create common group to be able to synchronize permissions to shared data volumes
RUN groupadd -g 777 www

# create missing tmp folder
RUN mkdir /tmp/nginx

CMD exec /usr/bin/supervisord -n -c /etc/supervisord.conf

