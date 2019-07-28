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

echo "Downloading national highways, which aren't tracked in ORMA"
aws s3 cp \
    "s3://$S3_DUMP_BUCKET/private-fixture-data/National_network.geojson" \
    National_network.geojson

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

        # TODO: this is just temporarily turning off appending national roads while
        # we debug https://github.com/orma/openroads-vn-analytics/issues/360

        # echo "Appending national roads for the province"
        # ../scripts/append-national-roads.js \
        #     National_network.geojson \
        #     target-boundary.geojson \
        #     data/output/Adj_lines.csv

        echo "Making network routable"
        python Network_Clean.py
        aws s3 cp \
            data/output/Network.csv \
            "s3://${S3_DUMP_BUCKET}/by-province-id/${province_code}.csv"
    fi

    rm target-boundary.geojson
    find data/* ! -name "*README.md" -type f -delete
done

echo "Successfully finished"
