FROM alpine:3.21

LABEL maintainer="JH <jh@localhost>"

ARG BUILD_DATE
ARG NAME
ARG VCS_REF
ARG VERSION

LABEL org.label-schema.schema-version="1.0" \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name=$NAME \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/johann8/" \
      org.label-schema.version=$VERSION

#ENV BACULA_VERSION=13.0.3-r0
ENV BACULA_VERSION=15.0.2-r0
ENV POSTGRES_VERSION=16
ENV BACULARIS_VERSION=4.8.0
ENV PACKAGE_NAME=standalone
ENV PHP_VERSION=84
ENV WEB_USER=nginx
# For PHP
ENV MEMORY_LIMIT=128M

RUN if [ "${PACKAGE_NAME}" = 'standalone' ] || [ "${PACKAGE_NAME}" = 'api-dir' ]; then \
       #apk add --no-cache postgresql14; \
       apk add --no-cache postgresql${POSTGRES_VERSION}-client; \
       #mkdir -m 0777 /run/postgresql; \
       #chown postgres:postgres /run/postgresql; \
    fi \
  && \ 
    if [ "${PACKAGE_NAME}" = 'standalone' ] || [ "${PACKAGE_NAME}" = 'web' ]; then \
       apk add --no-cache expect openssh-client iproute2-ss gnupg; \
    fi \
  && mkdir -m 0770 /run/bacula \
  && apk add --no-cache nginx curl tzdata tar \
  && apk add --no-cache \
         bacula=${BACULA_VERSION} \
         bacula-pgsql=${BACULA_VERSION} \
         bacula-client=${BACULA_VERSION} \
  && chown root:bacula /etc/bacula /etc/bacula/bacula-fd.conf /var/lib/bacula/archive \
  && chmod 775 /etc/bacula /var/lib/bacula/archive \
  && chown bacula:bacula /run/bacula \
  && addgroup ${WEB_USER} bacula \
  && apk add --no-cache bash sudo \
  && apk add --no-cache \
         php${PHP_VERSION}-bcmath \
         php${PHP_VERSION}-curl \
         php${PHP_VERSION}-dom \
         php${PHP_VERSION}-json \
         php${PHP_VERSION}-ldap \
         php${PHP_VERSION}-pdo \
         php${PHP_VERSION}-pgsql \
         php${PHP_VERSION}-pdo_pgsql \
         php${PHP_VERSION}-intl \
         php${PHP_VERSION}-ctype \
         php${PHP_VERSION}-session \
         php${PHP_VERSION}-fpm \
         php${PHP_VERSION}-openssl \
         php${PHP_VERSION}-gettext \
  && sed -i "/listen = / s!127.0.0.1:9000!/var/run/php-fpm.sock!; /user = / s!nobody!${WEB_USER}!; /group = / s!nobody!${WEB_USER}!; s!;listen.group!listen.group!" /etc/php${PHP_VERSION}/php-fpm.d/www.conf \
  && \
     if [ "${PACKAGE_NAME}" = 'standalone' ] || [ "${PACKAGE_NAME}" = 'api-dir' ]; then \
        # Fix job to backup catalog database
        sed -i 's!make_catalog_backup MyCatalog!make_catalog_backup bacula!' /etc/bacula/bacula-dir.conf; \
     fi

RUN tar czf /bacula-dir.tgz /etc/bacula

COPY "docker/systems/alpine/sudoers.d/bacularis-${PACKAGE_NAME}" /etc/sudoers.d/

COPY "docker/systems/alpine/entrypoint/docker-entrypoint.inc"  /

COPY "docker/systems/alpine/entrypoint/docker-entrypoint-${PACKAGE_NAME}.sh" /docker-entrypoint.sh

COPY rootfs/ /

RUN chmod 755 /docker-entrypoint.sh

COPY bacularis /var/www/bacularis

COPY "docker/systems/alpine/config/API/api-${PACKAGE_NAME}.conf" /var/www/bacularis/protected/vendor/bacularis/bacularis-api/API/Config/api.conf

COPY --chown=${WEB_USER}:${WEB_USER} common/config/API/* /var/www/bacularis/protected/vendor/bacularis/bacularis-api/API/Config/

COPY --chown=${WEB_USER}:${WEB_USER} common/config/Web/* /var/www/bacularis/protected/vendor/bacularis/bacularis-web/Web/Config/

RUN if [ "${PACKAGE_NAME}" = 'web' ]; then \
       rm /var/www/bacularis/protected/vendor/bacularis/bacularis-api/API/Config/*.conf; \
       rm /var/www/bacularis/protected/vendor/bacularis/bacularis-web/Web/Config/*.conf; \
       sed -i '/service id="oauth"/d; /service id="api"/d; /service id="panel"/d; s!BasePath="Bacularis.Common.Pages"!BasePath="Bacularis.Web.Pages"!; s!DefaultPage="CommonPage"!DefaultPage="Dashboard"!;' /var/www/bacularis/protected/application.xml; \
    fi \
  && \
    if [ "${PACKAGE_NAME}" = 'api-dir' ] || [ "${PACKAGE_NAME}" = 'api-sd' ] || [ "${PACKAGE_NAME}" = 'api-fd' ]; then \
       rm /var/www/bacularis/protected/vendor/bacularis/bacularis-web/Web/Config/*.conf; \
       sed -i 's!BasePath="Bacularis.Common.Pages"!BasePath="Bacularis.API.Pages.Panel"!; s!DefaultPage="CommonPage"!DefaultPage="APIHome"!; /service id="web"/d;' /var/www/bacularis/protected/application.xml; \
    fi \
  && /var/www/bacularis/protected/tools/install.sh -w nginx -c /etc/nginx/http.d -u ${WEB_USER} -d /var/www/bacularis/htdocs -p /var/run/php-fpm.sock

RUN tar czf /bacularis-app.tgz /var/www/bacularis

RUN tar czf /bacula-sd.tgz /var/lib/bacula

EXPOSE 9101/tcp 9102/tcp 9103/tcp 9097/tcp

#VOLUME ["/var/lib/postgresql/data", "/etc/bacula", "/var/lib/bacula", "/var/www/bacularis"]
VOLUME ["/var/lib/postgresql/data", "/etc/bacula", "/var/lib/bacula", "/var/www/bacularis/protected/vendor/bacularis/bacularis-api/API/Config", "/var/www/bacularis/protected/vendor/bacularis/bacularis-api/API/Logs", "/var/www/bacularis/protected/vendor/bacularis/bacularis-web/Web/Config", "/var/www/bacularis/protected/vendor/bacularis/bacularis-web/Web/Logs"]

ENTRYPOINT [ "/docker-entrypoint.sh" ]

CMD ["nginx", "-g", "daemon off;"]
