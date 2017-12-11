#!/bin/sh
set -e

echo "Ensure the necessary environment variables are set"
: "${DATABASE_URL:?}"
: "${AWS_ACCESS_KEY_ID:?}"
: "${AWS_SECRET_ACCESS_KEY:?}"
# Exclude the `S3_DUMP_BUCKET` environment variable if you
# don't want to push a backup to S3
# : "${S3_DUMP_BUCKET:?}"

# Change to submodule's directory
cd "${0%/*}"

WORKDIR=make-full-backup.tmp
rm -rf "$WORKDIR"
mkdir "$WORKDIR"

echo "Downloading contents of all database tables, to ${WORKDIR}"
psql "${DATABASE_URL}" -f full-backup.sql

if [ -n "$S3_DUMP_BUCKET" ]
then
    echo "Save the database backup to S3"
    zip -r "${WORKDIR}/full-backup.zip" "$WORKDIR"
    aws s3 cp \
        "${WORKDIR}/full-backup.zip" \
        "s3://${S3_DUMP_BUCKET}/full-backup/orma-backup-$(date +%Y-%m-%d).zip"
fi

echo "Successfully finished"
