# Bacularis and Bacula community edition

## Bacularis - The Bacula web interface
[Bacularis](https://github.com/bacularis/bacularis-app) is a web interface to configure, manage and monitor Bacula backup environment. It is a complete solution for setting up backup jobs, doing restore data, managing tape or disk volumes in local and remote storage, work with backup clients, and doing daily administrative work with backup.

## Bacula linux binaries
[Bacula](https://www.bacula.org/) linux binaries Deb / Rpm can be found on [Bacula website](https://www.bacula.org/bacula-binary-package-download/)
To access these binaries, you will need an access key, which will be provided when you complete a simple registration.

## Bacula windows binaries
[Bacula](https://www.bacula.org/)  windows binaries can be found on [Bacula website](https://www.bacula.org/binary-download-center/)

## Create bacula client config files
You can create client config files automatically. For this you can find some scripts and templates on the repo. You load the files into a directory and start the bash scripts. Run "scriptname -h / --help" to see help.

### For Linux
```bash
wget https://raw.githubusercontent.com/johann8/bacularis/master/1_create_new_bacula_client_linux--server_side_template.sh
wget https://raw.githubusercontent.com/johann8/bacularis/master/2_create_new_bacula_client_linux--client_side_template.sh
wget https://raw.githubusercontent.com/johann8/bacularis/master/bacula-dir_template.conf
wget https://raw.githubusercontent.com/johann8/bacularis/master/bacula-fd_template.conf
wget https://raw.githubusercontent.com/johann8/bacularis/master/bconsole_template.conf
```
- To create configuration for Bacula `Linux` client on server side, you need to pass two parameters to script 1, namely `client name` and `IP address`.
- To create configuration for Bacula `Linux` client on client side, you need to pass only one parametes to script 2, namely `client name`.
- The MD5 Bacula client password is automatically created by the script.
- The `bacula-mon` password you can read out from server configuration. After that you can insert the password into the script: `2_create_new_bacula_client_linux--client_side_template.sh`. The variable is called `DIRECTOR_CONSOLE_MONITOR_PASSWORD`. You must use single quote marks. As an example:\
`DIRECTOR_CONSOLE_MONITOR_PASSWORD='MySuperPassword'`
- An example: login to the server where docker container is running with bacula server. Pass the path to the configuration file and execute the commands below
```bash
BACULA_SERVER_CONFIG_DIR_DOCKER=/opt/bacularis/data/bacula/config/etc/bacula/bacula-dir.conf
cat ${BACULA_SERVER_CONFIG_DIR_DOCKER} |sed -n '/bacula-mon/,+1p' |grep Password |cut -f 2 -d '"'
vim 2_create_new_bacula_client_linux--client_side_template.sh            # And insert "bacula-mon" password    
```
- When everything is ready, run the scripts. As an example:
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
```bash
wget https://raw.githubusercontent.com/johann8/bacularis/master/3_create_new_bacula_client_windows--server_side_template.sh
wget https://raw.githubusercontent.com/johann8/bacularis/master/bacula-dir_template_windows.conf
```
- To create configuration for Bacula `Windows` client on server side, you need to pass two parameters to script 3, namely `client name` and `IP address`.
- The MD5 Bacula client password is automatically created by the script.
- When everything is ready, run the scripts. As an example:
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
- The MD5 bacula client password you can read out from config file `bacula-dir_win-srv01.conf`

```bash
cat config_files/bacula-dir_pc-vm01.conf | sed -n '/Client {/,+4p' | grep -w Password |cut -f 2 -d '"'
```

As a result comes something like this: `[md5]607e60c2c1f4f859679fbe9d742b0c59`

- 
```bash
ip addr show $(ip route | awk '/default/ {print $5}') |grep -w inet | awk '/inet/ {print $2}' | cut -d'/' -f1
```
As a result comes something like this: `192.168.155.15`

- Download [Bacula](https://www.bacula.org/) windows binaries from [Bacula website](https://www.bacula.org/binary-download-center/)
- Run bacula installation
- Fill in the data as in the picture
- Finish the installation
