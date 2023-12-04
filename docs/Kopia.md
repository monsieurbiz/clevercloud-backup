# Backup with Kopia

## Installation

See the "For backup with kopia" section in the [README.md](../README.md).

## Restore a backup

Connect to the kopia repository with the choosen password:
```
kopia repository connect s3 \
  --bucket=... \
  --access-key=... \
  --secret-access-key=... \
  --endpoint=cellar-c2.services.clever-cloud.com
```

Check the repository status to check the connection status: `kopia repository status`.

If you want to restore a backup directly on a clever instance, you can read the [functions.sh](../clevercloud/functions.sh#5) file to install kopia on your app.

### List all backups

```
kopia snapshot ls --all
```

You will see DB backups and file backups. 

Example:

```
bas@...:/home/bas/.../db-backups
  2023-12-04 15:33:52 CET kd2...786 20 B drwxr-xr-x files:1 dirs:1 (latest-2)
  2023-12-04 15:54:25 CET kf4...127 442.9 KB drwxr-xr-x files:1 dirs:1 (latest-1,hourly-1,daily-1,weekly-1,monthly-1,annual-1)

bas@...:/home/bas/.../sylius-prod-...
  2023-12-04 15:34:11 CET kca...08a 6.4 KB drwxr-xr-x files:15 dirs:9 (latest-1..2,hourly-1,daily-1,weekly-1,monthly-1,annual-1)
  + 1 identical snapshots until 2023-12-04 15:54:29 CET

bas@...:/home/bas/.../sylius-prod-media
  2023-12-04 15:33:54 CET k22...b42 499 MB drwxr-xr-x files:360 dirs:50 (latest-1..2,hourly-1,daily-1,weekly-1,monthly-1,annual-1)
  + 1 identical snapshots until 2023-12-04 15:54:27 CET
```

### Mount backup

Target the backup you want to restore.

For example in snapshot list:
```
  2023-11-29 10:00:02 CET k22...b42 499 MB drwxr-xr-x files:360 dirs:50 (latest-1..2,hourly-1,daily-1,weekly-1,monthly-1,annual-1)
```

The backup hash is `k22...b42`.

Create a tmp directory to mount the backup:
```
mkdir /tmp/backup
kopia mount k22...b42 /tmp/backup &
...
[1] 97123
```

*The `97123` number is the PID of the kopia command**

You will see the mouted folder: 
```
ooprint@sd-120444:~$ ls -l /tmp/backup/
...
```

### Restore the files

You need to specify the folder you want to sync.

```
rsync -av /tmp/backup/ ~/app_.../apps/sylius/public/media/ --update
```

You can change the folder if you want to restore a subfolder.

```
rsync -av /tmp/backup/<folder>/ ~/app_.../apps/sylius/public/media/<folder>/ --update
```

You can decide to override updated files in the server by the backup files by removing the `--update` option.

### Unmount the backup

The mount is running in a background process, so use the `kill` command to unmount the snapshot

```
kill -2 97123
```

Don't forget to exit it to unmount the volume.
