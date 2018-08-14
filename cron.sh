#!/bin/bash

echo export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID >> .env
echo export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY >> .env
echo export DATABASE_URL=$DATABASE_URL >> .env
echo export PATH=$PATH:/usr/local/bin >> .env
echo export S3_DUMP_BUCKET=$S3_DUMP_BUCKET >> .env
echo export S3_TEMPLATE=$S3_TEMPLATE >> .env
echo export MAPBOX_ACCOUNT=$MAPBOX_ACCOUNT >> .env
echo export MAPBOX_ACCESS_TOKEN=$MAPBOX_ACCESS_TOKEN >> .env
echo '*/5 * * * * . /opt/app/.env; cd /opt/app; ./scripts/make-network.sh >> make-network.log 2>&1' | crontab -
(crontab -l; echo '*/30 * * * * . /opt/app/.env; cd /opt/app; ./scripts/make-analysis-and-display.sh >> make-analysis-and-display.log 2>&1') | crontab -
(crontab -l; echo '* */24 * * * . /opt/app/.env; cd /opt/app; ./scripts/generate-tasks.sh >> generate-tasks.log 2>&1') | crontab -
(crontab -l; echo '* */2 * * * . /opt/app/.env; cd /opt/app; ./scripts/generate-routable-dumps.sh >> generate-routable-dumps.log 2>&1') | crontab -
(crontab -l; echo '* */24 * * * . /opt/app/.env; cd /opt/app; ./scripts/make-full-backup.sh >> make-full-backup.log 2>&1') | crontab -
cron start -f
