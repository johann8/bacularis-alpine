#!/usr/bin/env bash

set -e

trap stop SIGTERM SIGINT SIGQUIT SIGHUP ERR

. /docker-entrypoint.inc

# set variables
LOCAL_ADDRESS=${BUILD_DAEMON_NAME}
BACULA_DIR_CONFIG="/etc/bacula/bacula-dir.conf"
BACULA_SD_CONFIG="/etc/bacula/bacula-sd.conf"
BACULA_FD_CONFIG="/etc/bacula/bacula-fd.conf"
BCONSOLE_CONFIG="/etc/bacula/bconsole.conf"
B_VERSION=$(echo ${BACULA_VERSION} | awk -F- '{print $1}')
PHP_VERSION=84

function start()
{
    #start_postgresql
    start_bacula_dir
    start_bacula_sd
    start_bacula_fd
    start_php_fpm
}

function stop()
{
    stop_php_fpm
    stop_bacula_fd
    stop_bacula_sd
    stop_bacula_dir
    #stop_postgresql
}

echo ""
echo "+----------------------------------------------------------+"
echo "|                                                          |"
echo "|      Welcome to Bacula CE && Bacularis-APP Docker!       |"
echo "|                                                          |"
echo "+----------------------------------------------------------+"

echo ""
echo "+----------------------------------------------------------+"
echo "|         Starting  Bacularis-APP - Verison ${BACULARIS_VERSION}          |"
echo "+----------------------------------------------------------+"
echo ""

# Change Time Zone
echo -n "Changing PHP time zone...                "
sed -i "/date.timezone =/c\date.timezone = \"${TZ}\"" /etc/php${PHP_VERSION}/conf.d/custom.ini
echo "[done]"

# Set var memory_limit
echo -n "Setting \"memory_limit\" into custom.ini...       "
sed -i -e '/memory_limit =/c\memory_limit = "'${MEMORY_LIMIT}'"' /etc/php${PHP_VERSION}/conf.d/custom.ini
echo "[done]"

### control bacula config
if [ ! -f /etc/bacula/bacula-config.control ]; then
   tar xzf /bacula-dir.tgz --backup=simple --suffix=.before-control

   ### === Mail delivery ===
   if [ ! -z ${SMTP_HOST} ]; then
      # hostname & port 
      echo -n "Setting mail hostname & port...          "
      sed -i -e "s/-h localhost/-h ${SMTP_HOST}/g" ${BACULA_DIR_CONFIG}
      echo "[done]"
   fi

   # admin mail addresss
   if [ ! -z ${ADMIN_MAIL} ]; then
      echo -n "Setting admin user mail address...       "
      sed -i -e "s/mail = root@localhost/mail = ${ADMIN_MAIL}/g" \
             -e "s/operator = root@localhost/operator = ${ADMIN_MAIL}/g" ${BACULA_DIR_CONFIG}
      echo "[done]"
   fi

#  # Change Address of Autochanger, bacula-fd, bconsole
#  echo -n "Changing IP address to localhost...      "
#  sed -i -e "s/^  Address = ${LOCAL_ADDRESS}/  Address = localhost/" ${BACULA_DIR_CONFIG}
#  echo "[done]"

   # Change bacula-dir daemon name (build-3-19-x86_64)
   if [ ! -z ${BUILD_DAEMON_NAME} ]; then
      echo -n "Setting daemon names...                  "
      sed -i "s/${BUILD_DAEMON_NAME}/${DESIRED_DAEMON_NAME}/g" ${BACULA_DIR_CONFIG}
      sed -i "s/${BUILD_DAEMON_NAME}/${DESIRED_DAEMON_NAME}/g" ${BACULA_FD_CONFIG}
      sed -i "s/${BUILD_DAEMON_NAME}/${DESIRED_DAEMON_NAME}/g" ${BACULA_SD_CONFIG}
      sed -i "s/${BUILD_DAEMON_NAME}/${DESIRED_DAEMON_NAME}/g" ${BCONSOLE_CONFIG}
      #sed -i "s/address = ${DESIRED_DAEMON_NAME}/address = localhost/" ${BCONSOLE_CONFIG}
      echo "[done]"
   fi

   # Delete old pools; add storage pools: Full, Differential, Incremental
   if [[ "${ADD_STORAGE_POOL}" = true ]]; then
      # Delete old storage pools
      echo -n "Deleting old storage pools...            "
      sed -i -e '/# Default pool definition/,+10d' \
             -e '/# File Pool definition/,+11d' ${BACULA_DIR_CONFIG}
      echo "[done]"

      # Add storage pools: Full, Differential, Incremental
      echo -n "Creating storage pools...                "
      cat >> ${BACULA_DIR_CONFIG} << 'EOL'
Pool {
  Name = "Differential"
  Description = "Differential Pool"
  Storage = "File1"
  PoolType = "Backup"
  LabelFormat = "Differential-"
  MaximumVolumes = 10
  MaximumVolumeBytes = 25000000000
  VolumeRetention = 7776000
  AutoPrune = yes
  Recycle = yes
}

Pool {
  Name = "Full"
  Description = "Full Pool"
  Storage = "File1"
  PoolType = "Backup"
  LabelFormat = "Full-"
  MaximumVolumes = 10
  MaximumVolumeBytes = 53687091200
  VolumeRetention = 15552000
  AutoPrune = yes
  Recycle = yes
}

Pool {
  Name = "Incremental"
  Description = "Incremental Pool"
  Storage = "File1"
  PoolType = "Backup"
  LabelFormat = "Incremental-"
  MaximumVolumes = 10
  MaximumVolumeBytes = 15000000000
  VolumeRetention = 2592000
  MaximumVolumes = 10
  MaximumVolumeBytes = 10000000000
  VolumeRetention = 2592000
  AutoPrune = yes
  Recycle = yes
}
EOL
      echo "[done]"

      # Change docker bacula client
      echo -n "Changing backup job name...              "
      sed -i -e 's/Name = "BackupClient1"/Name = "backup-bacula-fd"/g' \
             -e 's/Pool = File/Pool = "Incremental"/g' \
             -e 's/Full Set/bacula-fd-fs/g' ${BACULA_DIR_CONFIG}
      echo "[done]"

      echo -n "Changing backup job description...       "     
      sed -i -e '/  Name = "backup-bacula-fd"/a\  Description = "Backup bacula docker container"' ${BACULA_DIR_CONFIG}
      echo "[done]"

      echo -n "Adding storage pools to jobdefs...       "
      sed -i -e '/  Name = "DefaultJob"/a\  DifferentialBackupPool = "Differential"' \
             -e '/  Name = "DefaultJob"/a\  IncrementalBackupPool = "Incremental"' \
             -e '/  Name = "DefaultJob"/a\  FullBackupPool = "Full"' ${BACULA_DIR_CONFIG}
      echo "[done]"

      echo -n "Changing DefaultJob name...              "
      sed -i -e 's/^  Name = "DefaultJob"/  Name = "bacula-fd-job"/' -e 's/^  JobDefs = "DefaultJob"/  JobDefs = "bacula-fd-job"/' ${BACULA_DIR_CONFIG}
      echo "[done]"
   fi

   # Delete bacula-fd old fileset
   echo -n "Deleting bacula-fd old fileset...        "
   sed -i -e '/# List of files to be backed up/,+38d' ${BACULA_DIR_CONFIG}
   echo "[done]"

   # Add bacula-fd new fileset
   echo -n "Creating bacula-fd new fileset...        "
   cat >> ${BACULA_DIR_CONFIG} << EOL

Fileset {
  Name = "${DESIRED_DAEMON_NAME}-fd-fs"
  Include {
    Options {
      Compression = "Lzo"
      Signature = "Sha1"
      OneFs = "yes"
    }
    File = "/var/www/bacularis/protected/vendor/bacularis/bacularis-api/API/Config/"
    File = "/var/www/bacularis/protected/vendor/bacularis/bacularis-web/Web/Config/"
    File = "/etc/bacula"
    File = /var/lib/bacula
  }
  Exclude {
    File = /var/lib/bacula/archive
    File = /proc
    File = /tmp
    File = /sys
    File = /.journal
    File = /.fsck
  }
}
EOL
   echo "[done]"

   #
   echo -n "Setting bacula config permissions...     "
   #chown -R bacula:bacula /etc/bacula/*
   chown bacula:tape /var/lib/bacula/archive && addgroup bacula tape
   #chmod -R 775 /etc/bacula/*
   echo "[done]"

   # Set bacula-sd ip address
   if [ ! -z ${DOCKER_HOST_IP} ]; then
      # Storage File1
      n1=
      echo -n "Setting Storage \"File1\" IP address...    "
      n1=$(cat ${BACULA_DIR_CONFIG} |grep -niw 'Name = File1' | awk -F: '{ print $1 }')
      n1=$(($n1+2))
      sed -i -e "${n1}s+localhost+${DOCKER_HOST_IP}+" ${BACULA_DIR_CONFIG}
      echo "[done]"

      # Storage File2
      echo -n "Setting Storage \"File2\" IP address...    "
      n2=
      n2=$(cat ${BACULA_DIR_CONFIG} |grep -niw 'Name = File2' | awk -F: '{ print $1 }')
      n2=$(($n2+2))
      sed -i -e "${n2}s+localhost+${DOCKER_HOST_IP}+" ${BACULA_DIR_CONFIG}
      echo "[done]"
   fi

   # Control file
   touch /etc/bacula/bacula-config.control
fi

### Control bacula storage 
if [ ! -f /var/lib/bacula/bacula-sd.control ]; then
   tar xzf /bacula-sd.tgz --backup=simple --suffix=.before-control

   # Control file
   touch /var/lib/bacula/bacula-sd.control
fi

### Control bacularis-app
if [ ! -f /var/www/bacularis/protected/Web/Config/bacularis-app.control ]; then
   tar xzf /bacularis-app.tgz --backup=simple --suffix=.before-control

   # Add PostgresDB access data into bacula-dir.conf
   echo -n "Setting PostgresDB data to bacula-dir... "
   sed -i "/dbname = \"/c\  dbname = \"${DB_NAME}\"; dbuser = \"${DB_USER}\"; dbpassword = \"${DB_PASSWORD}\"; dbaddress = \"${DB_HOST}\"; dbport = \"${DB_PORT}\"" ${BACULA_DIR_CONFIG}
   echo "[done]"

   # Add PostgresDB access data into api.conf
   API_CONF_PFAD="/var/www/bacularis/protected/vendor/bacularis/bacularis-api/API/Config/api.conf"
   echo -n "Setting PostgresDB data to API...        "
   sed -i "/name = \"/c\name = \"${DB_NAME}\"" ${API_CONF_PFAD}
   sed -i "/login = \"/c\login = \"${DB_USER}\"" ${API_CONF_PFAD}
   sed -i "/password = \"/c\password = \"${DB_PASSWORD}\"" ${API_CONF_PFAD}
   sed -i "/ip_addr = \"/c\ip_addr = \"${DB_HOST}\"" ${API_CONF_PFAD}
   echo "[done]"

  # Set admin user & password
  if [ ! -z ${WEB_ADMIN_USER} ] && [ ! -z ${WEB_ADMIN_PASSWORD_ENCRYPTED} ] && [ ! -z ${WEB_ADMIN_PASSWORD_DECRYPT} ]; then
     echo -n "Setting admin user name...               "
     sed -i "/login =/c\login = \"${WEB_ADMIN_USER}\"" /var/www/bacularis/protected/vendor/bacularis/bacularis-web/Web/Config/hosts.conf
     echo "[done]"

     echo -n "Setting admin user password encrypted... "
     sed -i '/admin:/c\'${WEB_ADMIN_USER}':'${WEB_ADMIN_PASSWORD_ENCRYPTED}'' /var/www/bacularis/protected/vendor/bacularis/bacularis-api/API/Config/bacularis.users
     sed -i '/admin:/c\'${WEB_ADMIN_USER}':'${WEB_ADMIN_PASSWORD_ENCRYPTED}'' /var/www/bacularis/protected/vendor/bacularis/bacularis-web/Web/Config/bacularis.users
     echo "[done]"

     echo -n "Setting admin user password decrypt...   "
     sed -i "/password =/c\password = \"${WEB_ADMIN_PASSWORD_DECRYPT}\"" /var/www/bacularis/protected/vendor/bacularis/bacularis-web/Web/Config/hosts.conf
     echo "[done]"
  fi

  # Control file
  touch /var/www/bacularis/protected/Web/Config/bacularis-app.control
fi


#
### === PostgresDB ===
#
export PGUSER=${DB_ADMIN_USER}
export PGHOST=${DB_HOST}
export PGPASSWORD=${DB_ADMIN_PASSWORD}
[[ -z "${DB_INIT}" ]] && DB_INIT='false'
[[ -z "${DB_UPDATE}" ]] && DB_UPDATE='false'

# PostgresDB helthcheck
if [[ -z ${CI_TEST} ]] ; then
   # Waiting Postgresql is up
   sqlup=1
   while [ "$sqlup" -ne 0 ] ; do
      echo "Waiting for postgresql..."
      pg_isready --host="${DB_HOST}" --port="${DB_PORT}" --user="${DB_ADMIN_USER}"
      if [ $? -ne 0 ] ; then
         sqlup=1
         sleep 5
      else
         sqlup=0
         echo "...postgresql is alive"
      fi
   done
fi

# Init PostgresDB
if [ ! -f /etc/bacula/bacula-db.control ] && [ "${DB_INIT}" == 'true' ] ; then

   # Add pgpass file to ${DB_USER} home
   homedir=$(getent passwd "$DB_USER" | cut -d: -f6)
   echo "${DB_HOST}:${DB_PORT}:${DB_NAME}:${DB_USER}:${DB_PASSWORD}" > "${homedir}/.pgpass"
   chmod 600 "${homedir}/.pgpass"
   chown "${DB_USER}" "${homedir}/.pgpass"

   # Init Postgres DB
   echo "*** Bacula DB init ***"
   echo "Bacula DB init: Create user ${DB_USER}"
   psql -c "create user ${DB_USER} with createdb createrole login;"
   echo "Bacula DB init: Set user password"
   psql -c "alter user ${DB_USER} password '${DB_PASSWORD}';"
   /etc/bacula/scripts/create_bacula_database 2>/dev/null
   /etc/bacula/scripts/make_bacula_tables  2>/dev/null
   /etc/bacula/scripts/grant_bacula_privileges  2>/dev/null
   # Control file
   touch /etc/bacula/bacula-db.control
fi

# Update Postgres DB
if [ "${DB_UPDATE}" == 'true' ] ; then
   # Try Postgres upgrade
   echo "*** Bacula DB update ***"
   echo "Bacula DB update: Update tables"
   /etc/bacula/scripts/update_bacula_tables  2>/dev/null
   echo "Bacula DB update: Grant privileges"
   /etc/bacula/scripts/grant_bacula_privileges  2>/dev/null
fi

# Update script folder to new version
# check var POSTGRES_VERSION not empty
if [[ -n ${POSTGRES_VERSION} ]]; then

   # determine postgres client version
   POSTGRES_CLIENT_VERSION=$(cat /usr/libexec/postgresql/PG_VERSION)

   if [[ ${POSTGRES_VERSION} -eq ${POSTGRES_CLIENT_VERSION} ]]; then
      # do nothing
      echo "Posgres server and client have the same version."
   else
      # Folder "scripts_old_version" exist
      if [[ -d /etc/bacula/scripts_old_version ]]; then 

         echo "Deleting old script folder... "
         rm -rf /etc/bacula/scripts_old_version

         # run function
         update_script_folder	  

      # Folder "scripts_old_version" does not exist
      else
         # run function
         update_script_folder
      fi
   fi
fi 

echo ""
echo "+----------------------------------------------------------+"
echo "|           Starting  Bacula CE - Verison ${B_VERSION}           |"
echo "+----------------------------------------------------------+"
echo ""

# Run services
start

exec "$@"
