#!/bin/bash -l

set -o errexit -o nounset -o xtrace

if [[ "${INSTANCE_NUMBER}" != "0" ]]; then
    return 0;
fi

if [[ "${BACKUP_APP}" == "" ]]; then
    return 0;
fi

cd $APP_HOME

clever login --token $CLEVER_TOKEN --secret $CLEVER_SECRET
clever link --alias _backup_app $BACKUP_APP
clever env --alias _backup_app set BACKUP_PLEASE_MY_LOVELY_SCRIPT true
clever restart --quiet --alias _backup_app
