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
for province_code in "207" "507" "203" "201" "405" "209" "205" "113" "403" "814" "503" "409" "401" "411"
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
