#!/bin/bash

echo export DATABASE_URL=$DATABASE_URL >> .env
echo export S3_BUCKET=$S3_BUCKET >> .env
echo export PATH=$PATH:/usr/local/bin >> .env
echo '*/5 * * * * . /opt/app/.env; cd /opt/app; node index.js >> /opt/app/cron.log 2>&1' | crontab
cron start -f
