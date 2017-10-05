#!/bin/bash

echo export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID >> .env
echo export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY >> .env
echo export DATABASE_URL=$DATABASE_URL >> .env
echo export PATH=$PATH:/usr/local/bin >> .env
echo export S3_DUMP_BUCKET=$S3_DUMP_BUCKET >> .env
echo export S3_PROPERTIES_BUCKET=$S3_PROPERTIES_BUCKET >> .env
echo export WHICH_SCRIPT=$WHICH_SCRIPT >> .env
echo '*/5 * * * * . /opt/app/.env; cd /opt/app; node index.js >> /opt/app/cron.log 2>&1' | crontab
cron start -f
