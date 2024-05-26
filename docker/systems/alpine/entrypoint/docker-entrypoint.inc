#!/bin/bash

export PGDATA='/var/lib/postgresql/data'
POSTGRESQL_USER='postgres'
BACULA_USER='bacula'
PHP_VERSION=83

function initdb()
{
    chown ${POSTGRESQL_USER} ${PGDATA}
    chmod 700 ${PGDATA}
    su ${POSTGRESQL_USER} -c 'initdb'
}

function start_postgresql()
{
    if [ -z "$(ls -A "$PGDATA")" ];
    then
        initdb
    fi
    su ${POSTGRESQL_USER} -c 'pg_ctl start'
}

function stop_postgresql()
{
        su ${POSTGRESQL_USER} -c "pg_ctl stop"
}

function init_bacula()
{
        su ${POSTGRESQL_USER} -c '/etc/bacula/scripts/create_postgresql_database'
        su ${POSTGRESQL_USER} -c '/etc/bacula/scripts/make_postgresql_tables'
        su ${POSTGRESQL_USER} -c '/etc/bacula/scripts/grant_postgresql_privileges'
}

function start_bacula_dir()
{
    if ! su ${POSTGRESQL_USER} -c 'psql -l' | grep '^ bacula' 1>/dev/null
    then
        init_bacula
    fi

    /etc/bacula/scripts/bacula-ctl-dir start
}

function stop_bacula_dir()
{
    /etc/bacula/scripts/bacula-ctl-dir stop
}

function start_bacula_sd()
{
    /etc/bacula/scripts/bacula-ctl-sd start
}

function stop_bacula_sd()
{
    /etc/bacula/scripts/bacula-ctl-sd stop
}

function start_bacula_fd()
{
    /etc/bacula/scripts/bacula-ctl-fd start
}

function stop_bacula_fd()
{
    /etc/bacula/scripts/bacula-ctl-fd stop
}

function start_php_fpm()
{
    php-fpm${PHP_VERSION}
}

function stop_php_fpm()
{
    kill `pidof php-fpm83`
}
