#!/bin/bash -l

set -o errexit -o nounset -o xtrace

if [[ "${INSTANCE_NUMBER}" != "0" ]]; then
    return 0;
fi

clever login --token $CLEVER_TOKEN --secret $CLEVER_SECRET
clever link --alias _backup_app $BACKUP_APP
clever env --alias _backup_app set BACKUP_PLEASE_MY_LOVELY_SCRIPT true
clever start --quiet --alias _backup_app
