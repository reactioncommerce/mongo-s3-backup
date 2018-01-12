#!/bin/bash

set -e

#
# AWS configs
#
if [ -z "$AWS_ACCESS_KEY_ID" ]; then
  echo "AWS_ACCESS_KEY_ID must be set"
  exit 1
fi

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
  echo "AWS_SECRET_ACCESS_KEY must be set"
  exit 1
fi

if [ -z "$S3_BUCKET" ]; then
  echo "S3_BUCKET must be set"
  exit 1
fi

#
# Mongo configs
#
if [ -z "$MONGO_HOST" ]; then
  # default to a linked container with name "mongo"
  MONGO_HOST="mongo"
fi

if [[ "$MONGO_DATABASE" ]]; then
  MONGO_HOST+=" --db $MONGO_DATABASE"
fi

#
# backup configs
#
if [ -z "$DATE_FORMAT" ]; then
  DATE_FORMAT="%Y%m%d_%H%M%S"
fi

if [ -z "$FILE_PREFIX" ]; then
  FILE_PREFIX=""
fi

function restore {
  aws s3api get-object --bucket $S3_BUCKET --key $FILE /backup/$FILE
  tar -zxvf /backup/$FILE -C /backup
  mongorestore --drop --host $MONGO_HOST $MONGORESTORE_FLAGS dump/
  rm -rf dump/ /backup/$FILE
}

# backup
if [ "$1" == "backup" ]; then
  printf "\nStarting backup...\n\n"

  DATE=$(date +$DATE_FORMAT)
  FILENAME=$FILE_PREFIX$DATE.tar.gz
  FILE=/backup/$FILENAME

  mongodump --host $MONGO_HOST $MONGODUMP_FLAGS
  tar -zcvf $FILE dump/
  printf "\nUploading $FILENAME...\n\n"
  aws s3api put-object --bucket $S3_BUCKET --key $FILENAME --body $FILE
  rm -rf dump/ $FILE

# list backups
elif [ "$1" == "list" ]; then
  printf "\nRetrieving backups from $S3_BUCKET...\n\n"
  aws s3api list-objects --bucket $S3_BUCKET --query 'Contents[].{Key: Key, Size: Size}' --output table

# restore
elif [ "$1" == "restore" ]; then
  if [ -z "$2" ]; then
    echo "Name of a dump to restore is required"
    exit 1
  fi
  if [ "$2" == "latest" ]; then
    printf "\nDetermining backup to restore...\n\n"
    : ${FILE:=$(aws s3 ls s3://$S3_BUCKET | awk -F " " '{print $4}' | grep ^$FILE_PREFIX | sort -r | head -n1)}
    printf "\nStarting restore of $FILE...\n"
    restore
  else
    FILE=$2
    printf "\nStarting restore of $FILE...\n\n"
    restore
  fi
fi
