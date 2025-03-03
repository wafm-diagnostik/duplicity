# duplicity Backups

_Plugin containers for docker-compose to create backups using duplicity_

## Custom Images

Following custom images are build using docker multi-stage build and appropriate targets in the actual build. They are based on [docker-duplicity](https://github.com/Tecnativa/docker-duplicity).

- `ghcr.io/wafm-diagnostik/duplicity-base:main` \
  Base Image for all WAfM Backup Jobs, defining a weekly full-backup (Job 500) and a weekly cleanup of old backups (Job 999). The cleanup retains the last three full-backups including their increments.
- `ghcr.io/wafm-diagnostik/duplicity-mysql:main` \
  Extending the base Image by adding mysql client utilities. A mysql dump job is added too (Job 201). \
  The Job is set up to run daily and weekly and dumps all databases to `$SRC/mysql-database-dump.sql`. \
  The dump is always saved under the same name. This allows duplicity to properly back up increments of the dump. \
  The Job accepts the following Environment variables for configuration:
  - `BKP_DB_SERVER` hostname of server to dump
  - `BKP_DB_USER` username for mysql server
  - `BKP_DB_PASS` password for mysql server

## Intended Strategy

To back up data from a Service Stack, the following setup is required

1. docker volume for local backups
   ```yaml
   volumes:
       # onsite backup target, shared among systems which backup data
       duplicity-destination:
           external: true
   ```
2. add one of the duplicity containers to the stack and configure it appropriately
   ```yaml
   services:
       ...
       backup:
           image: ghcr.io/wafm-diagnostik/duplicity-mysql:main
           # hostname is required for duplicity
           # think of it as your backup name
           hostname: my-service-backup
           restart: unless-stopped
           depends_on:
               - mysql
           volumes:
               - duplicity-destination:/backups
               # mount folders you want to back up to "/mnt/backup/src/xxx"
               # everything found in "/mnt/backup/src/" will be backed up
               - ./some/folder:/mnt/backup/src/some-folder:ro
           environment:
               # set proper timezone for duplicity to be able to tag the backups accordingly
               - TZ=Europe/Berlin
               # this should match the volume target of duplicity-destination with some folder added
               # IMPORTANT: duplicity always uses the same name for backup files
               # this folder has to be different per docker-compose
               - DST=file:///backups/my-service
               - BKP_DB_SERVER=mysql
               - BKP_DB_USER=root
               - BKP_DB_PASS=s3cre7-d4tab4se-p4ssw0rd
               - PASSPHRASE=superSecretBackupEncryptionKey
   ```
 
## Backup type and schedule

**Full Backup**s are created weekly at 1 AM, on Sundays. (`JOB 500`) \
**Incremental Backup**s are created at 2 AM, from Monday to Saturday (`JOB 300`)

The MySQL Version creates full database dumps in weekly and daily backups (`JOB 201`)

A weekly job cleanes up the backups and deletes everything but the last 3 full backups and their incrementals (`JOB 999`)

## Where are they stored?

All Backups are written to the globally available (external) docker volume `duplicity-destination`.
