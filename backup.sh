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
chunkSize=30

# Setup S3
envsubst < $APP_HOME/s3cfg.dist > $APP_HOME/s3cfg

# Backup MySQL databases
# Format to use: BACKUP_MYSQL(_[0-9]+)?=user:pass:host:port:database:alias
env | grep BACKUP_MYSQL | while read line; do
    IFS=":" read -r user pass host port db alias <<< `echo $line | awk -F= {'print $2'}`
    # Dump & Upload
    mysqldump -v -e \
        --single-transaction \
        --no-tablespaces \
        --column-statistics=0 \
        -h$host -P$port -u$user -p$pass $db \
    | gzip \
    | s3cmd -c $APP_HOME/s3cfg put - --multipart-chunk-size-mb=$chunkSize s3://$BACKUP_BUCKET/$alias.$db.$date.sql.gz
done;

# Backup filesystems
# @todo List of ignored files
env | grep BACKUP_PATH | while read -r line; do
    read backupPath <<< `echo $line | awk -F= {'print $2'}`
    pathname=`basename $backupPath`
    # Compress & Upload
    tar -cvzpf - \
        --force-local \
        --directory=$APP_HOME/$backupPath \
        --exclude-vcs \
        --exclude=cache/* . \
    | s3cmd -c $APP_HOME/s3cfg put - --multipart-chunk-size-mb=$chunkSize s3://$BACKUP_BUCKET/$pathname.$date.tgz
done;

# Latest backup date
echo $date | s3cmd -c $APP_HOME/s3cfg put - s3://$BACKUP_BUCKET/latest_backup_date.txt

# Remove old files
s3cmd -c $APP_HOME/s3cfg ls s3://$BACKUP_BUCKET | while read -r line;
do
    createDate=`echo $line | awk {'print $1" "$2'}`
    createDate=`date -d"$createDate" +%s`
    olderThan=`date -d"-$BACKUP_KEEP" +%s`
    if [[ $createDate -lt $olderThan ]]
    then
        fileName=`echo $line | awk {'print $4'}`
        echo $fileName
        if [[ $fileName != "" ]]
        then
            s3cmd -c $APP_HOME/s3cfg del "$fileName"
        fi
    fi
done;

# List the cellar
s3cmd -c $APP_HOME/s3cfg ls s3://$BACKUP_BUCKET | sort -r | head -50
