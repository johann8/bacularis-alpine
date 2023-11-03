<h1 align="center">Bacularis and Bacula community edition - Docker</h1>

- [Docker Images](#docker-images) 
- [Bacula](#bacula)
  - [Bacula linux binaries](#bacula-linux-binaries)
  - [Bacula windows binaries](#bacula-windows-binaries)
  - [Create bacula client config files](#create-bacula-client-config-files)
- [Bacularis](#bacularis---the-bacula-web-interface)
  - [For Linux](#for-linux)
  - [For Windows](#for-windows)
- [Install docker container](#install-docker-container)
  - [Docker variables](#docker-variables)
  - [Access WebUI](#access-webui)
  - [Access bconsole](#access-bconsole)
  - [Firewall rules](#firewall-rules)
  - [Docker Exim Relay Image](#docker-exim-relay-image)
  - [Traefik integration](#traefik-integration)
  - [Authelia integration](#authelia-integration)
- [Backup](#backup)
  - [Backup mysql database](#backup-mysql-database)
  - [Backup postgres database](#backup-postgres-database)
- [My Docker hub](#my-docker-hub)

## Docker images 🐋

Images are based on [Ubuntu 22](https://hub.docker.com/repository/docker/johann8/bacularis/general) or [Alpine 3.18](https://hub.docker.com/repository/docker/johann8/bacularis/general). Unfortunately, [Alpine](https://pkgs.alpinelinux.org/packages?page=1&branch=v3.18&name=bacula%2A) repository does not include a cloud driver for bacula storage. Bacula community repository for [Ubuntu](https://www.bacula.org/packages/6367abb52d166/debs/13.0.2/dists/jammy/main/binary-amd64/), on the other hand, does have a cloud driver for bacula storage. Therefore I had to create two docker images. Ubuntu docker image does have a cloud driver for bacula storage.

| pull | size ubuntu | size alpine | version ubuntu | version alpine | platform |
|:---------------------------------:|:--------------------------------:|:----------------------------------:|:--------------------------------:|:--------------------------------:|:--------------------------------:|
| ![Docker Pulls](https://img.shields.io/docker/pulls/johann8/bacularis?logo=docker&label=pulls&style=flat-square&color=blue) | ![Docker Image Size](https://img.shields.io/docker/image-size/johann8/bacularis/latest-ubuntu?logo=docker&style=flat-square&color=blue&sort=semver) | ![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/johann8/bacularis/latest-alpine?logo=docker&style=flat-square&color=blue&sort=semver) | [![](https://img.shields.io/docker/v/johann8/bacularis/latest-ubuntu?logo=docker&style=flat-square&color=blue&sort=semver)](https://hub.docker.com/r/johann8/bacularis/tags "Version badge") | [![](https://img.shields.io/docker/v/johann8/bacularis/latest-alpine?logo=docker&style=flat-square&color=blue&sort=semver)](https://hub.docker.com/r/johann8/bacularis/tags "Version badge") | ![](https://img.shields.io/badge/platform-amd64-blue "Platform badge") |


| ALpine version | Ubuntu version | Bacularis version |
|:---------------------------------:|:--------------------------------:|:--------------------------------:|
| [![Alpine Version](https://img.shields.io/badge/Alpine%20version-v3.18.0-blue.svg?style=flat-square)](https://alpinelinux.org/) | [![Ubuntu Version](https://img.shields.io/badge/Ubuntu%20version-22.04-blue.svg?style=flat-square)](https://ubuntu.com/) | [![Bacularis Version](https://img.shields.io/badge/Bacularis%20version-2.1.2-orange.svg?style=flat-square)](https://bacularis.app/) |

## Bacula
[Bacula](https://www.bacula.org/) is a set of Open Source, computer programs that permit you to manage backup, recovery, and verification of computer data across a network of computers.

## Bacularis - The Bacula web interface
[Bacularis](https://github.com/bacularis/bacularis-app) is a web interface to configure, manage and monitor Bacula backup environment. It is a complete solution for setting up backup jobs, doing restore data, managing tape or disk volumes in local and remote storage, work with backup clients, and doing daily administrative work with backup.

## Bacula linux binaries
[Bacula](https://www.bacula.org/) linux binaries Deb / Rpm can be found on [Bacula website](https://www.bacula.org/bacula-binary-package-download/). To access these binaries, you will need an access key, which will be provided when you complete a simple registration.

## Bacula windows binaries
[Bacula](https://www.bacula.org/)  windows binaries can be found on [Bacula website](https://www.bacula.org/binary-download-center/).

## Install docker container

- Create folders, set permissions

```bash
mkdir -p /opt/bacularis/data/{bacularis,bacula,pgsql}
mkdir -p /opt/bacularis/data/bacularis/www/bacularis-api/API/{Config,Logs}
mkdir -p /opt/bacularis/data/bacularis/www/bacularis-web/Web/{Config,Logs}
mkdir -p /opt/bacularis/data/bacula/{config,data}     
mkdir -p /opt/bacularis/data/bacula/config/etc/bacula
mkdir -p /opt/bacularis/data/bacula/data/director
mkdir -p /opt/bacularis/data/pgsql/{data,socket}
mkdir -p /opt/bacularis/data/smtp/secret
tree -d -L 4 /opt/bacularis
```
- Create [docker-compose.yml](https://github.com/johann8/bacularis-alpine/blob/master/docker-compose.yml)\
or
- Download all files below

```bash
cd /opt/bacularis
wget https://raw.githubusercontent.com/johann8/bacularis-alpine/master/docker-compose.yml
wget https://raw.githubusercontent.com/johann8/bacularis-alpine/master/docker-compose.override.yml
wget https://raw.githubusercontent.com/johann8/bacularis-alpine/master/1_create_new_bacula_client_linux--server_side_template.sh
wget https://raw.githubusercontent.com/johann8/bacularis-alpine/master/2_create_new_bacula_client_linux--client_side_template.sh
wget https://raw.githubusercontent.com/johann8/bacularis-alpine/master/3_create_new_bacula_client_windows--server_side_template.sh
wget https://raw.githubusercontent.com/johann8/bacularis-alpine/master/bacula-dir_template.conf
wget https://raw.githubusercontent.com/johann8/bacularis-alpine/master/bacula-dir_template_windows.conf
wget https://raw.githubusercontent.com/johann8/bacularis-alpine/master/bacula-fd_template.conf
wget https://raw.githubusercontent.com/johann8/bacularis-alpine/master/bconsole_template.conf
wget https://raw.githubusercontent.com/johann8/bacularis-alpine/master/.env
chmod u+x *.sh
```
- Customize variables in all files
- Generate `admin` user `password` [here](https://www.web2generators.com/apache-tools/htpasswd-generator). You need both passwords decrypt and encrypted

```
# Example
Username: admin
Password: N04X1UYYbZ2J69sAYLb0N04
```

- Customize the file `docker-compose.override.yml` if you use [trafik](https://traefik.io/)
- Run docker container

```bash
cd /opt/bacularis
docker-compose up -d
docker-compose ps
docker-compose logs
docker-compose logs bacularis
```
# Docker variables

- Bacularis docker container

| Variable | Value | Description |
|:------------------------|:-------------------------|:-------------------------------------------------|
| TZ | Europe/Berlin | Time zone |
| DB_INIT | true or false | true - required for DB init only (first run) |
| DB_UPDATE | false or true | true - required for DB update only |
| DB_HOST | bacula-db | PostgreSQL db host name  |
| DB_PORT | 5432 | PostgreSQL db port  |
| DB_NAME | bacula  | bacula database name |
| DB_USER | bacula  | bacula user name  |
| DB_PASSWORD | MyDBPassword  | password use to access to the bareos database |
| DB_ADMIN_USER | postgres  | PostgreSQL root user name (required for DB init only) |
| DB_ADMIN_PASSWORD | MyDBAdminPassword | Password for PostgreSQL root user (required for DB init only) |
| BUILD_DAEMON_NAME | build-3-17-x86_64 |  from alpine assigned bacula daemons name |
| DESIRED_DAEMON_NAME | bacula | desired name for bacula daemons |
| WEB_ADMIN_USER | admin | User name for bacula web interface |
| WEB_ADMIN_PASSWORD_DECRYPT | MyWebPassword  | User password (decrypt) for bacula web interface |
| WEB_ADMIN_PASSWORD_ENCRYPTED | $apr1$1fvq6ki0$AScxxxx | User password (encrypted) for bacula web interface  |
| SMTP_HOST | smtpd:8025 | docker container smtp service - name & port |
| ADMIN_MAIL | admin@mydomain.de | your email address |
| ADD_STORAGE_POOL | true or false | true - standard pool are replaced by Incremental, Differential and Full |
| DOCKER_HOST_IP | 192.168.2.10 | IP address of docker host |
| DOCKERDIR | /opt/bacularis | Docker container config and data folder |
| PORT_BACULARIS | 9097 | Bacula port for Web interface |
| PORT_STORAGE | 9103  | Bacula port for storage daemon: bacula-sd |
| PORT_DIRECTOR | 9101  | Bacula port for director daemon: bacula-dir  |

- bacula-db docker container

| Variable | Value | Description |
|:------------------------|:-------------------------|:-------------------------------------------------|
| TZ | Europe/Berlin | Time zone |
| DB_ADMIN_USER | postgres | PostgreSQL root user name (required for DB init only) |
| DB_ADMIN_PASSWORD | MyPostgresRootPassword | Password for PostgreSQL root user (required for DB init only) |

- smtpd docker container

| Variable | Value | Description |
|:------------------------|:-------------------------|:-------------------------------------------------|
| HOSTNAME_SMTP | bacularis.mydomain.de | hostname of smtp server |
| SMARTHOST | smtp.mydomain.de | smtp server FQDN |
| SMTP_USERNAME | backup@mydomain.de | smtp server user name |
| SMTP_PASSWORD | SmtpUserPassword | smtp server user password |


## Access WebUI

- Open `http://host.domain.com:9097` or via traefik `https://host.domain.com` in your web browser then sign-in
- Login with your `admin` user credentials (user: `admin` / pass: `<ADMIN_PASSWORD_DECRYPT>`)
- Check the `bacula director` settings

## Access bconsole

- With docker
```bash
docker exec -it bacularis bconsole
```

- With docker-compose
```bash
cd /opt/bacularis
docker-compose exec bacularis bconsole
```

## Firewall rules

Ports that need to be opened in firewall.

| port | protocol | description |
|-------------------:|:--------------------:|:-------------------------------------------------|
| 9102 | TCP |For bacula-fd file daemon |
| 9103 | TCP |For bacula-sd storage daemon |
| 9097 | TCP |For Bacularis-APP without RP (Traefik) |
|  443 | TCP |For Bacularis-APP with RP (Traefik) |

- Example for CentOS/Oracle/Rocky Linux

```bash
firewall-cmd --permanent --zone=public --add-port=9102/tcp
firewall-cmd --permanent --zone=public --add-port=9103/tcp
firewall-cmd --permanent --zone=public --add-port=9097/tcp
firewall-cmd --permanent --zone=public --add-port=443/tcp
firewall-cmd --reload
firewall-cmd --list-all
```
## Docker Exim Relay Image
[Exim mail relay](https://exim.org) is a lightweight Docker image, based on the official Alpine image. You can see the documentation for this [here](https://github.com/devture/exim-relay) 


## Create bacula client config files
You can create client config files automatically. For this you can find some scripts and templates on the repo. You load the files into a directory and start the bash scripts. Run `scriptname -h / --help` to see help.

### For Linux

---
- Download files below in a directory

```bash
wget https://raw.githubusercontent.com/johann8/bacularis-alpine/master/1_create_new_bacula_client_linux--server_side_template.sh
wget https://raw.githubusercontent.com/johann8/bacularis-alpine/master/2_create_new_bacula_client_linux--client_side_template.sh
wget https://raw.githubusercontent.com/johann8/bacularis-alpine/master/bacula-dir_template.conf
wget https://raw.githubusercontent.com/johann8/bacularis-alpine/master/bacula-dir_template_windows.conf
wget https://raw.githubusercontent.com/johann8/bacularis-alpine/master/bacula-fd_template.conf
wget https://raw.githubusercontent.com/johann8/bacularis-alpine/master/bconsole_template.conf
chmod u+x *.sh
```
- To create configuration for Bacula `Linux` client on server side, you need to pass two parameters to script 1, namely `client name` and `IP address`
- To create configuration for Bacula `Linux` client on client side, you need to pass only one parametes to script 2, namely `client name`
- The MD5 Bacula client password is automatically created by the script
- The `bacula-mon` password you can read out from server configuration. After that you can insert the password into the script: `2_create_new_bacula_client_linux--client_side_template.sh`. The variable is called `DIRECTOR_CONSOLE_MONITOR_PASSWORD`. You must use single quote marks. Here is an example:\
`DIRECTOR_CONSOLE_MONITOR_PASSWORD='MySuperPassword'`
- An example: login to the server where docker container is running with bacula server. Adjust the path of `bacula-dir` configuration file and execute the commands below

```bash
BACULA_SERVER_CONFIG_DIR_DOCKER=/opt/bacularis/data/bacula/config/etc/bacula/bacula-dir.conf
cat ${BACULA_SERVER_CONFIG_DIR_DOCKER} |sed -n '/bacula-mon/,+1p' |grep Password |cut -f 2 -d '"'
vim 2_create_new_bacula_client_linux--client_side_template.sh            # And insert "bacula-mon" password    
```
- When everything is ready, run the scripts to create bacula linux client config files. Here is an example:

```bash
./1_create_new_bacula_client_linux--server_side_template.sh -n srv01 -ip 192.168.155.5
./2_create_new_bacula_client_linux--client_side_template.sh -n srv01
```
- The created files can be found in the folder `config_files`. The content of the file `bacula-dir_srv01.conf` is added to the configuration file `bacula-dir.conf` of the `bacula server`

```bash
cat config_files/bacula-dir_srv01.conf >> /opt/bacularis/data/bacula/config/etc/bacula/bacula-dir.conf
cd /opt/bacularis && docker-compose exec bacularis bash
bconsole
reload
```
- The created files `bacula-fd_srv01.conf` and `bconsole_srv01.conf` must be copied to client by folder `/opt/bacula/etc`

```bash
cd /opt/bacula/etc
# create backup of old files
mv bacula-fd.conf bacula-fd.conf.back
mv bconsole.conf bconsole.conf.back

# rename files
mv bacula-fd_srv01.conf bacula-fd.conf
mv bconsole_srv01.conf bconsole.conf
systemctl restart bacula-fd.service
```
### For Windows

---
- Download files below in a directory

```bash
wget https://raw.githubusercontent.com/johann8/bacularis-alpine/master/3_create_new_bacula_client_windows--server_side_template.sh
wget https://raw.githubusercontent.com/johann8/bacularis-alpine/master/bacula-dir_template_windows.conf
chmod u+x *.sh
```

- To create configuration for Bacula `Windows` client on server side, you need to pass two parameters to script 3, namely `client name` and `IP address`
- The MD5 Bacula client password is automatically created by the script
- When everything is ready, run the scripts to create bacula windows client config files. Here is an example:

```bash
./3_create_new_bacula_client_windows--server_side_template.sh -n win-srv01 -ip 192.168.155.8
```
- The created files can be found in the folder `config_files`. The content of the file `bacula-dir_win-srv01.conf` is added to the configuration file `bacula-dir.conf` of the `bacula server`

```bash
cat config_files/bacula-dir_win-srv01.conf >> /opt/bacularis/data/bacula/config/etc/bacula/bacula-dir.conf
cd /opt/bacularis && docker-compose exec bacularis bash
bconsole
reload
```
### Bacula Windows client install

For the installation of Bacula Windows client you need the name of Bacula Director `bacula-dir`, MD5 password of bacula windows client and the ip address of docker host.

- You can read out MD5 bacula client password from created config file `bacula-dir_win-srv01.conf`

```bash
cat config_files/bacula-dir_win-srv01.conf | sed -n '/Client {/,+4p' | grep -w Password |cut -f 2 -d '"'
```

As a result comes something like this: `[md5]607e60c2c1f4f859679fbe9d742b0c59`

- You need the ip address of `docker host`. This ip address is specified as `bacula-dir` ip address. You can execute the following command on `docker host` to find out the ip address:

```bash
ip addr show $(ip route | awk '/default/ {print $5}') |grep -w inet | awk '/inet/ {print $2}' | cut -d'/' -f1
```
As a result comes something like this: `192.168.155.15`

- Download [Bacula](https://www.bacula.org/) windows binaries from [Bacula website](https://www.bacula.org/binary-download-center/)
- Run bacula installation
- Fill in the data as in the picture
![Bacula_Windows_Install](https://raw.githubusercontent.com/johann8/bacularis-alpine/master/docs/assets/screenshots/bacula_win_install.png)
- Finish the installation
- Open the file `C:\Program Files\Bacula\bacula-fd.conf`
- Find the section

```
#
# List Directors who are permitted to contact this File daemon
#
Director {
  Name = bacula-dir
  Password = "Ck7WxwW8xfew45stslKdXoPGIAk+8QyB07tli92W1XWC"        # Director must know this password

```

- Replace the password with the MD5 password from the client

```
#
# List Directors who are permitted to contact this File daemon
#
Director {
  Name = bacula-dir
  Password = "[md5]607e60c2c1f4f859679fbe9d742b0c59"        # Director must know this password

```

- Restart Windows bacula daemon
- Windows firewall configuration - unblock ports 9102/TCP and 9103/TCP for incoming rules

## Traefik integration
- create docker-compose.override.ym

```bash
vim docker-compose.override.yml
---------------------------
version: "3.0"
networks:
  proxy:
    external: true

services:
  bacularis:
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=proxy"
      - "traefik.http.routers.bacularis-secure.entrypoints=websecure"
      - "traefik.http.routers.bacularis-secure.rule=Host(`$HOSTNAME0.$DOMAINNAME`)"
      - "traefik.http.routers.bacularis-secure.service=bacularis"
      #- "traefik.http.routers.bacularis-secure.tls.certresolver=produktion"             # für eigene Zertifikate
      - "traefik.http.routers.bacularis-secure.tls.options=modern@file"
      - "traefik.http.routers.bacularis-secure.tls=true"
      - "traefik.http.routers.bacularis-secure.middlewares=default-chain@file,rate-limit@file,authelia@file"
      #- "traefik.http.routers.bacularis-secure.middlewares=default-chain@file,rate-limit@file"
      - "traefik.http.services.bacularis.loadbalancer.sticky.cookie.httpOnly=true"
      - "traefik.http.services.bacularis.loadbalancer.sticky.cookie.secure=true"
      - "traefik.http.services.traefik.loadbalancer.server.port=${PORT}"
    networks:
      - proxy
```


## Authelia integration
Authelia docker container is located on the other host `IP: 192.168.15.7/32` `FQDN: auth.mydomain.de` \
Traefik docker container is located on the same host as `bacularis` docker container `IP: 192.168.15.16/32`

- `traefik` container: add middleware `authelia` into traefik config file

```bash
vim /opt/traefik/data/conf/traefik.yml
--------------------------------------
...
http:
...
  middlewares:
...
    authelia:
      forwardAuth:
        address: "http://auth.mydomain.de:9091/api/verify?rd=https://auth.mydomain.de/"
        trustForwardHeader: true
...

# restart `Traefik` docker container
cd /opt/traefik && docker-compose up -d
```

- `authelia` container: change `docker-compos.yml` as below

```bash
vim docker-compos.yml
--------------------
...
    ports:
      - 9091:9091
...
```

- `authelia` container: add FQDN for bacularis web `bacularis.mydomain.de`

```bash
vim /opt/authelia/data/authelia/config/configuration.yml
--------------------------------------------------------
...
access_control:
  default_policy: deny 
  rules:
    - domain:
...
    - domain: bacularis.mydomain.de
      policy: one_factor
...

# restart `authelia` docker container
cd /opt/authelia && docker-compose up -d
```

- `authelia` container host: add firewall rule for access to `auth.mydomain.de` port 9091 from `bacularis` docker container host `IP: 192.168.15.16/32`

```bash
firewall-cmd --permanent --zone=public --add-rich-rule='rule family="ipv4" port port="9091" protocol="tcp" source address="192.168.15.16/32" accept'
firewall-cmd --reload
firewall-cmd --zone=public --list-all
```

# Backup
## Backup mysql database

- Download script below to the client

```bash
cd /opt/bacula/scripts/
wget https://raw.githubusercontent.com/johann8/bacularis-alpine/master/scripts/backup_mysql.sh
chmod a+x backup_mysql.sh
cd -
```
- Start Bacularis-App and browse to: Director => Configure director => Job => Name => Edit => +Add => +Add Runscript block
- Fill out as in the picture (Path to the location of the script)
![Job_Add_run_script](https://github.com/johann8/bacularis-alpine/raw/master/docs/assets/screenshots/add_run_script_job.png)

- Browse to: Director => Configure director => Fileset => Name => Edit => Include #1 +Add => +Add single file/directory
- Fill out as in the picture (Var "DST" from script /var/backup/container/mysql)
![Fileset_Add_singe_file_directory](https://github.com/johann8/bacularis-alpine/raw/master/docs/assets/screenshots/fileset_add_single_file-directory.png)

## Backup postgres database

For Postgres DB backup the Script [autopostgresqlbackup](https://github.com/k0lter/autopostgresqlbackup) is used. There is a [docker container](https://hub.docker.com/r/rogersik/autopostgresqlbackup) with this script. You can find a description and configaration example [here](https://gitea.sikorski.cloud/RogerSik/docker-autopostgresqlbackup).

- Here is an example of how to backup Postgres database in a docker container

```bash
# create backup destination
mkdir -p /var/backup/container/postgres

# Add to the Docker container where the dostgres database runs

...
  autopgbackup:
    image: rogersik/autopostgresqlbackup:latest
    container_name: autopgbackup
    environment:
      - DBHOST=${POSTGRES_HOST}
      - USERNAME=${POSTGRES_USER}
      - PASSWORD=${POSTGRES_PASSWORD}
      - CRON_LOG_LEVEL=0                            # Most verbose is 0, less verbose is 8
      - CRON_SCHEDULE=50 22 * * *                   # valid cron specification
      - LATEST=yes                                  # Additionally keep a copy of the most recent backup in a seperate directory
    volumes:
     - /var/backup/container/postgres:/backups
     - /etc/localtime:/etc/localtime:ro
    depends_on:
      - postgresdb
...
```
- Start Bacularis-App and browse to: Director => Configure director => Fileset => Name => Edit => Include #1 +Add => +Add single file/directory
- Fill out as in the picture (Volume path fron docker-compose.yml: /var/backup/container/postgres)
![Fileset_Add_singe_file_directory](https://github.com/johann8/bacularis-alpine/raw/master/docs/assets/screenshots/fileset_add_single_file-directory.png)

## My Docker hub

- [Docker images](https://hub.docker.com/repository/docker/johann8/bacularis/general)

Enjoy !
