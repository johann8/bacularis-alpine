<h1 align="center">Upgrade PostgresDB from version 16 to version 17</h1>



##  Upgrade Postgres Datenbank

??? tip "Planka: Upgrade Postgres Version 14 zu Version 16"

    - Auf `bash` im Container zugreifen

    ```bash
    cd /opt/bacularis
    docker compose exec bacula-db bash

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
    mkdir data/postgres/db-data
    chown 70 data/postgres/db-data
    chmod 0700 data/postgres/db-data
    ```

    - Verzeichnisstruktur anzeigen lassen

    ```bash title="ls -la data/postgres/"
    drwx------  2   70 root 4096 21. Feb 12:07 db-data
    drwx------ 19   70 root 4096 21. Feb 12:07 db-data_14
    ```




- Update with the script [`updateDMS.sh`](https://github.com/johann8/tools?tab=readme-ov-file#install-updatedmssh-script)

```bash

cd /opt/bacularis
./updateDMS.sh

```

