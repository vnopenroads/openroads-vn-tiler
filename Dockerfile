FROM ubuntu:16.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -y
RUN apt-get install -y build-essential software-properties-common curl git mercurial && add-apt-repository ppa:ubuntu-toolchain-r/test
RUN apt-get update -y
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash -
RUN apt-get install -y nodejs 
RUN apt-get install apt-transport-https
RUN apt-get install -y libstdc++-5-dev zip

# Get psql
RUN apt-get install -y postgresql-client

# Get tippecanoe
RUN apt-get install -y libprotobuf-dev protobuf-compiler libsqlite3-dev && git clone https://github.com/mapbox/tippecanoe.git && cd tippecanoe && make && make install

# Get AWS CLI and Mapbox CLI
# The Ubuntu Trusty version of `requests` is insufficient for `mapboxcli` uploads
RUN apt-get install -y python-pip && pip install --upgrade requests && npm install -g mapbox-upload geojson-stream-merge


# Install node modules
ENV NPM_CONFIG_LOGLEVEL=warn
ADD package.json /tmp/package.json
RUN cd /tmp && npm i
RUN mkdir -p /opt/app && cp -a /tmp/node_modules /opt/app/

RUN node -v 

# Change to app directory
WORKDIR /opt/app
ADD . /opt/app

CMD ["sh", "/opt/app/cron.sh"]
