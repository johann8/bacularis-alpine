<h1 align="center">Upgrade PostgresDB from version 16 to version 17</h1>



##  Upgrade Postgres Datenbank

### Vorbereitungen

- Auf `bash` im Container zugreifen

```bash
cd /opt/bacularis
docker compose exec bacula-db bash
```

- Info über die Datenbank anzeigen lassen

```bash
### show databases, users and rights
# psql --username postgres --dbname bacula
psql --username postgres

postgres=# \l
postgres=# \du
postgres=# \q
exit
```

- Rechte für den PostgresDB Ordner anzeigen lassen

```bash 
ls -la data/postgres/
----
drwx------ 19   70 root 4096 20. Feb 23:26 db-data
----

ls -la data/postgres/db-data/
----
...
drwx------  6   70   70  4096 18. Jul 2022  base
drwx------  2   70   70  4096 20. Feb 23:27 global
...
----
```

- `Dump` von PostgresDB "bacula" erstellen

```bash
docker compose exec bacula-db pg_dump -U postgres -d bacula -cC > upgrade_backup_pg16.sql    
```

- Ergebnis anzeigen lassen

```bash title="ls -lah"
-rw-r--r--  1 root root 326M 25. Feb 15:25 upgrade_backup_pg16.sql
```

- Monitoring Tool `monit` anhalten

```bash
systemctl stop monit
systemctl status monit
```

- Docker Stack anhalten

```bash
cd /opt/bacularis
docker compose down
```

- Altes PostgresDB Verzeichnis umbenennen

```bash
mv data/postgres/db-data data/postgres/db-data_16
```

- Neues PostgresDB Verzeichnis erstellen

```bash
mkdir -p data/postgres/{db-data,socket}
chown 70 data/postgres/db-data
chown 70 data/postgres/socket
chmod 0700 data/postgres/db-data
chmod 0700 data/postgres/socket
```

- Verzeichnisstruktur anzeigen lassen

```bash title="ls -la data/postgres/"
drwx------  2   70 root 4096 21. Feb 12:07 db-data
drwx------ 19   70 root 4096 21. Feb 12:07 db-data_14
```
### Upgrade starten

- Datei `docker-compose.yml` ändern

```bash
cd /opt/bacularis
vim docker-compose.yml
----
services:
  bacularis:
    ...
    environment:
      ...
      - DB_INIT=true                                            #should be 'true' if bareos db does not exist
      ...
----
```

- Datei `.env` ändern

```bash
cd /opt/bacularis
vim .en
----
...
#DB_VERSION=16-alpine
DB_VERSION=17-alpine
...
----
```

- Download PostgresDB Docker Image Version 17

```bash
docker compose pull
```

- Start Docker Stack

```bash
docker compose up -d
docker compose ps

docker compose logs -f
----
bacula-db     | 2025-12-18 15:23:17.673 CET [73] FATAL:  password authentication failed for user "bacula"
bacula-db     | 2025-12-18 15:23:17.673 CET [73] DETAIL:  Connection matched file "/var/lib/postgresql/data/pg_hba.conf" line 128: "host all all all scram-sha
----
```

- Stop Docker Stack

```bash
docker compose down
```

- `SUBNET` anzeigen lassen

```bash
cat .env |grep SUBNET
----
SUBNET=172.26.5
----
```
- Datei `pg_hba.conf` ändern

```bash
vim data/postgres/db-data/pg_hba.conf
----
# IPv4 local connections:
host    all             all             127.0.0.1/32            trust
host    all             all             172.26.5.0/24           trust
----
```

- Start Docker Stack

```bash
docker compose up -d
docker compose ps
docker compose logs -f
```
- Prüfe, ob die Startseite von bacularis erreichbar ist

```bash
https://mydomain.de/web/
```

- Wenn Startseite erreichbar ist

```bash
# Stop Docker Stack
docker compose down
docker compose ps

# Starte PostgresDB Docker Container
docker compose up -d bacula-db
docker compose ps
docker compose logs -f
```
### PostgresDB `dump` wiederherstellen

- Die Größe des Datenbankordners zeigen und `Restore` starten

```bash
ncdu data/postgres/db-data/
cat upgrade_backup_pg16.sql | docker compose exec -T bacula-db psql -U postgres
ncdu data/postgres/db-data/
```

- Auf `bash` im Container zugreifen

```bash
cd /opt/bacularis
docker compose exec bacula-db bash
```

- Info über die Datenbank anzeigen lassen

```bash
### show databases, users and rights
# psql --username postgres --dbname bacula
cd /opt/bacularis
docker compose exec bacula-db bash
psql --username postgres

# list db
postgres=# \l
--------------                                                     List of databases
   Name    |  Owner   | Encoding  | Locale Provider |  Collate   |   Ctype    | Locale | ICU Rules |   Access privileges
-----------+----------+-----------+-----------------+------------+------------+--------+-----------+-----------------------
 bacula    | bacula   | SQL_ASCII | libc            | C          | C          |        |           |
 postgres  | postgres | SQL_ASCII | libc            | en_US.utf8 | en_US.utf8 |        |           |
 template0 | postgres | SQL_ASCII | libc            | en_US.utf8 | en_US.utf8 |        |           | =c/postgres          +
           |          |           |                 |            |            |        |           | postgres=CTc/postgres
 template1 | postgres | SQL_ASCII | libc            | en_US.utf8 | en_US.utf8 |        |           | =c/postgres          +
           |          |           |                 |            |            |        |           | postgres=CTc/postgres
------------

# list user
postgres=# \du
------------
                             List of roles
 Role name |                         Attributes
-----------+------------------------------------------------------------
 bacula    | Create role, Create DB
 postgres  | Superuser, Create role, Create DB, Replication, Bypass RLS
------------

# postgres shell verlassen
postgres=# \q

# PostgesDB Version anzeigen lassen
psql -V

# container verlassen
exit
```

- Stop Docker Stack

```bash
docker compose down
docker compose ps
```

- Datei `docker-compose.yml` ändern

```bash
cd /opt/bacularis
vim docker-compose.yml
----
services:
  bacularis:
    ...
    environment:
      ...
      - DB_INIT=false                                            #should be 'true' if bareos db does not exist
      ...
----
```

### Nacharbeiten


- Inhalt des Ordens "data/bacula/config/etc/" auflisten

```bash
cd /opt/bacularis
ls -la data/bacula/config/etc/
----
...
drwxr-x--x 2 root root  4096  6. Dez 2024  scripts
drwxr-x--x 2 root root  4096  5. Mär 2024  scripts_old_version
----
```

- Alten Ordner `scripts_old_version` löschen, falls existiert

```bash
rm -rf data/bacula/config/etc/scripts_old_version
```

- Ordner `scripts` sichern

```bash
# Ordner "scripts" sichern
```bash
mv data/bacula/config/etc/scripts data/bacula/config/etc/scripts_old_version
ls -la data/bacula/config/etc/
```
Im Docker container `bacularis` befindet sich eine Sicherung vom Ordner `/etc/bacula/scripts`. Dise Sicherung muss im Container entpackt und nach `/etc/bacula/` verschoben werden. In dem Ordner `/etc/bacula/scripts` befinden sich `bacula scripts` für die PostgresDB Version 17.

- Auf `bash` im Container zugreifen

```bash
cd /opt/bacularis
docker compose exec bacula-db bash
```

- Archiv `bacula-dir.tgz` nach `/tmp` entpacken

```bash
tar -xzvf /bacula-dir.tgz -C /tmp/
```

- Prüfen, ob es die richtige Version für PostgresDB 17 ist 

```bash
cat /tmp/etc/bacula/scripts/make_catalog_backup |grep libexec
----
    BINDIR=/usr/libexec/postgresql17
----
```

- Ordner `scripts` nach `/etc/bacula/` verschieben

```bash
mv /tmp/etc/bacula/scripts /etc/bacula/scripts
```
- Aufräumen

```bash
rm -rf /tmp/etc
```
- Inhalt des Ordens `/etc/bacula` auflisten und Docker Container verlassen

```bash
# Inhalt des Ordens anzeigen lassen 
ls -la /etc/bacula
----
...
drwxr-x--x 2 root root  4096  6. Dez 2024  scripts
drwxr-x--x 2 root root  4096  5. Mär 2024  scripts_old_version
----

# Container verlassen
exit
```
- Docker Stack anhalten und starten

```bash
docker compose up --force-recreate -d
docker compose ps
docker compose logs -f
```

- Prüfen, ob die Startseite von bacularis erreichbar ist und testen die Funktion

```bash
https://mydomain.de/web/
```

