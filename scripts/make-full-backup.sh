#!/bin/sh
set -e

echo "Ensure the necessary environment variables are set"
: "${DATABASE_URL:?}"

# Change to submodule's directory
cd "${0%/*}"

WORKDIR=make-full-backup.tmp
rm -rf "$WORKDIR"
mkdir "$WORKDIR"

echo "Downloading contents of all database tables, to ${WORKDIR}"
psql "${DATABASE_URL}" -f full-backup.sql

echo "Save the database backup to local"
zip -r "${WORKDIR}/full-backup.zip" "$WORKDIR"
mkdir -p ../backup/full-backup/
cp "${WORKDIR}/full-backup.zip" "../backup/full-backup/orma-backup-$(date +%Y-%m-%d).zip"

echo "Successfully finished"
