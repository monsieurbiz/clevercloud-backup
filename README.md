# Clever Cloud Backup App

This project is quite simple.  
We have an application which runs the backup script itself.

## Setup

You must create a `static-apache` or `php` application:

```
clever create -a backup -o "ORG NAME or ID" --type static-apache --region par --github "monsieurbiz/clevercloud-backup" "backup-app"
clever scale -a backup --flavor M
clever config -a backup update --enable-zero-downtime --enable-cancel-on-push
```

Once the app is created you should remove the domain attached to your app.

**Don't forget to link the Cellar on which you want to upload the backups!**

### Environment variables

The application uses some environment variables to run: (those can be in a `$config` addon in Clever Cloud)

- `CLEVER_TOKEN` and `CLEVER_SECRET` are mandatory as well, both for the backup application and the main application.  
  You *must* create a dedicated member in your Organization so those credentials are safe.
- `BACKUP_KEEP=30 days` to keep only backups for 30 days, as example here.
- `BACKUP_BUCKET=project-backups` is the name of the bucket we need to use in the S3 Cellar.
- `BACKUP_APP=app_…` is the code of the backup application itself. The backup script tests this value to be the same as its own `$APP_ID`.
- `BACKUP_MYSQL_*=user:pass:host:port:database:alias` (optional) are specific variables for MySQL backups. The format is quite simple, the fields are `:` separated.  
  The `alias` is used for the backup filename, it helps a lot since Clever Cloud databases are quite random.
- `BACKUP_PATH_*=path/from/app/this-is-my-backup` (optional) are specific variables for FileSystem backups. Each variable contains a path of the files to backup.  
  The directory name is used for the tarball file, so please be careful on this!

Of course your Backup Application needs to have the FS Buckets mounted where they have to.  
As example for the `BACKUP_PATH` previously set, you should have a bucket mounted like this:  
`CC_FS_BUCKET_1=path/from/app/this-is-my-backup:fs_bucket_host`

Some other environment variables are need for the backup application only (not in the `$config` addon!!):
- `CC_RUN_COMMAND=./backup.sh` tells Clever Cloud to run the backup script on startup.
- `CC_TASK=true` tells Clever Cloud to stop the application once the backup is finished.

Running the backup application will create an environment variable named `BACKUP_PLEASE_MY_LOVELY_SCRIPT`, this is perfectly normal.

The backup application also has access to those variables through the linked Cellar:
- `CELLAR_ADDON_HOST`
- `CELLAR_ADDON_KEY_ID`
- `CELLAR_ADDON_KEY_SECRET`

**For backup with kopia**

```
clever env -a backup set CC_PRE_RUN_HOOK ./clevercloud/pre_run_hook.sh
clever env -a backup set CC_RUN_COMMAND ./backup-kopia.sh
```

## How to run the backup itself?

You need to copy the `backup-please.sh` script into your own main application.
Then you can use a cronjob like this:

```
0 */12 * * * $ROOT/backup-please.sh
```

Your main app will need the following variables as well: `CLEVER_TOKEN`, `CLEVER_SECRET`, `BACKUP_APP`.  
Using a `$config` addon is helpful.

Enjoy!

## Troubleshooting

### How to SSH on the Backup App instance ?

You just need to set two specific environment variables: `CC_TROUBLESHOOT=true` and `CC_PRE_BUILD_HOOK=false`

Then you just have to start the instance! And use the Clever Cloud CLI to SSH to it!

## License

This project is completely free and released under the [MIT License](https://github.com/monsieurbiz/clevercloud-backup/blob/master/LICENSE.txt).
