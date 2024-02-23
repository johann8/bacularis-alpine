<h1 align="center">Bacula - Backup docker container</h1>

- [Backup using bash script](#backup-docker-container-using-bash-script)
- [Backup using Bacula docker plugin](#backup-docker-container-using-bacula-docker-plugin)
  - [Bacula linux binaries](#bacula-linux-binaries)

## Backup docker container using bash script

- Change `Director` config `bacula-dir.conf`
```bash
# You need to pass the variable `before | after` to script
# Example for client `oracle8-fd`

# Stop docker stack
cd /opt/bacularis
dc down

vim /opt/bacularis/data/bacula/config/etc/bacula/bacula-dir.conf
-------------------
Job {
  Name = "backup-oracle8-docker-stopScript"
  Description = "Backup all docker container with container stop script"
  JobDefs = "oracle8-docker-stopScript-job"
  Runscript {
    RunsWhen = "Before"
    Command = "/opt/bacula/scripts/script_before_after.sh before"
  }
  Runscript {
    RunsWhen = "After"
    Command = "/opt/bacula/scripts/script_before_after.sh after"
  }
}
Fileset {
  Name = "oracle8-docker-stopScript-fset"
  Description = "Backup all docker container with container stop script"
  EnableVss = no
  Include {
    File = "/opt"   
    Options {
      Compression = "LZO"
      Signature = "SH1"
      exclude = yes
    }
  }
  Exclude {
    File = "/opt/containerd"
    File = "/opt/lost+found"
    File = "/opt/bacularis"
    File = "/opt/bacularisalp"	
  }
}
JobDefs {
  Name = "oracle8-docker-stopScript-job"
  Description = "Backup all docker container with container stop script"
  Type = "Backup"
  Level = "Incremental"
  Messages = "Standard"
  Storage = "File1"
  Pool = "Incremental"
  FullBackupPool = "Full"
  IncrementalBackupPool = "Incremental"
  DifferentialBackupPool = "Differential"
  Client = "oracle8-fd"
  Fileset = "oracle8-docker-stopScript-fset"
  Schedule = "WeeklyCycle"
  WriteBootstrap = "/opt/bacula/working/%c.bsr"
  SpoolAttributes = yes
  Priority = 10
}
-------------------
```

- Download bash script into install path `/opt/bacula/scripts`
```bash
wget https://raw.githubusercontent.com/johann8/bacularis-alpine/master/container_backup_before_after.sh -O /opt/bacula/scripts/script_before_after.sh
chmod a+x /opt/bacula/scripts/script_before_after.sh
cd /opt/bacularis
docker-compose up -d
docker-compose ps
docker-compose logs
docker-compose logs bacularis
```

## Backup docker container using Bacula docker plugin

