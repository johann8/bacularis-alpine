<h1 align="center">Upgrade Bacula from version 13.0.3 to version 15.0.2</h1>

Register [here](https://www.bacula.org/bacula-binary-package-download/) to receive `access-key`\
You might find the [Community installation guide](https://www.bacula.org/whitepapers/CommunityInstallationGuide.pdf) very useful

## Upgrade Bacula Docker container 

```bash
# Stop monit service
systemctl status monit
systemctl stop monit
systemctl status monit

# Upgrade Bacularis Version von 13 to 15
cd /opt/bacularis
docker-compose exec bacularis bash

aa96f4fdcd6a:/# which bacula-dir
/usr/sbin/bacula-dir

/usr/sbin/bacula-dir -t -u bacula -g bacula
bacula-dir: dird.c:1540-0 Could not open Catalog "MyCatalog", database "bacula".
bacula-dir: dird.c:1546-0 Version error for database "bacula". Wanted 1026, got 1024
06-Dec 21:31 bacula-dir ERROR TERMINATION

# Show OS version
cat /etc/os-release

# Add new script folder to bacula from backup
mv /etc/bacula/scripts /etc/bacula/scripts_old_version
tar -xzvf /bacula-dir.tgz -C /tmp/
mv /tmp/etc/bacula/scripts /etc/bacula
ls -la /etc/bacula

# Exit docker container
exit

### Change docker-compose.yml to run postgres db update
# before
cd /opt/bacularis
vim docker-compose.yml
----------
...
      - DB_UPDATE=false
...
      - BUILD_DAEMON_NAME=build-3-19-x86_64                      # build name of bacula director daemon
...
----------

# after
----------
...
      - DB_UPDATE=true
...
      - BUILD_DAEMON_NAME=build-3-21-x86_64                      # build name of bacula director daemon
...
----------

# Rerun docker container
docker-compose down
docker-compose up -d

# Show if postgres db update done
docker-compose logs

# Stop docker container
docker-compose down

# Change docker-compose.yml
vim docker-compose.yml
----------
...
      - DB_UPDATE=false
...
----------

# Start docker container
docker-compose up -d

# Show logs
docker-compose logs

# Start monit service
systemctl start monit
systemctl status monit

# Login to web interface
# Check that everything is working
```
