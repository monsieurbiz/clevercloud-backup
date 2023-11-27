#!/bin/bash -l

set -o errexit

# If we are not the backup app, let's stop
if [[ "$BACKUP_APP" != "$APP_ID" ]]; then
    echo "The backup app is incorrect. Both APP_ID and BACKUP_APP are different." 1>&2
    exit 0
fi

# Sure?
if [[ "$BACKUP_PLEASE_MY_LOVELY_SCRIPT" != "true" ]]; then
    echo "This app is running without the safety flag BACKUP_PLEASE_MY_LOVELY_SCRIPT set to true. It won't backup."
    exit 0
fi

# Do not backup twice in a row, let's be sure of that!
clever login --token $CLEVER_TOKEN --secret $CLEVER_SECRET
clever link --alias _myself $APP_ID
clever env --alias _myself set BACKUP_PLEASE_MY_LOVELY_SCRIPT false

cd $APP_HOME

date=`date '+%Y%m%d%H%M%S'`

# Check if connected repository or try to connect to it
kopia repository status ||  kopia repository connect s3 \
  --bucket=$BACKUP_BUCKET \
  --access-key=$CELLAR_ADDON_KEY_ID \
  --secret-access-key=$CELLAR_ADDON_KEY_SECRET \
  --endpoint=$CELLAR_ADDON_HOST \
  --override-hostname=${APP_ID}

SERVICE_EXIT_STATUS=$?
if [ $SERVICE_EXIT_STATUS -ne 0 ];then
  echo "Error while connecting to the repository"
  exit 1
fi

# Backup MySQL databases
# Format to use: BACKUP_MYSQL(_[0-9]+)?=user:pass:host:port:database:alias
mkdir -p $APP_HOME/db-backups
env | grep BACKUP_MYSQL | while read line; do
    IFS=":" read -r user pass host port db alias <<< `echo $line | awk -F= {'print $2'}`
    # Dump & Upload
    mysqldump -v -e \
        --single-transaction \
        --no-tablespaces \
        --column-statistics=0 \
        -h$host -P$port -u$user -p$pass $db \
    | gzip > $APP_HOME/db-backups/$alias.$db.$date.sql.gz

    kopia snapshot create $APP_HOME/db-backups
done;

# Backup filesystems
env | grep BACKUP_PATH | while read -r line; do
    read backupPath <<< `echo $line | awk -F= {'print $2'}`

    # @TODO: ignore list
    kopia policy set --add-ignore cache ${APP_HOME}/${backupPath}

    kopia snapshot create ${APP_HOME}/${backupPath}
done;

# Verifying Validity of Snapshots
kopia snapshot verify
SERVICE_EXIT_STATUS=$?
if [ $SERVICE_EXIT_STATUS -ne 0 ];then
    echo "Please check the validity the Ooprint snapshots and fix them: https://kopia.io/docs/advanced/consistency/#repairing-corruption" \
        | mail -s "Kopia Snpashots are unvalid" ${ALERT_EMAIL}
fi;
