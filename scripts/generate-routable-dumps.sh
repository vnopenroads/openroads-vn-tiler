#!/bin/sh
set -e

echo "Ensure the necessary environment variables are set"
: "${DATABASE_URL:?}"
: "${AWS_ACCESS_KEY_ID:?}"
: "${AWS_SECRET_ACCESS_KEY:?}"
: "${S3_DUMP_BUCKET:?}"

# Change to submodule's directory
cd "${0%/*}"
cd ../Network_Cleaning

echo "For each province, generate and upload a routable road dump"
# For now, just hard-code the fourteen trial provinces
# This style of fetching roads will be replaced by the January deliverable
for province_code in "02" "03" "04" "09" "21" "22" "23" "24" "25" "26" "27" "31" "53" "67"
do
    echo "Generating routable road dump for province ${province_code}"
    psql "${DATABASE_URL}" -f export-prepped-from-database.sql -v province_code=$province_code

    # If there are no roads for that province, no need to process or upload
    if [ "$(wc -l < data/output/Adj_lines.csv)" -eq 1 ]
    then
        echo "No roads found for province ${province_code}"
        continue
    else
        python Network_Clean.py
        aws s3 cp \
            --acl public-read \
            data/output/Network.csv \
            "s3://${S3_DUMP_BUCKET}/by-province-id/${province_code}.csv"
    fi

    find data/* ! -name "*README.md" -type f -delete
done

echo "Successfully finished"
