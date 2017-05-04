FROM ubuntu:14.04

ENV DEBIAN_FRONTEND noninteractive

# Get node and yarn
RUN sudo apt-get update -y
RUN apt-get install -y build-essential software-properties-common curl git && add-apt-repository ppa:ubuntu-toolchain-r/test
RUN curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
RUN apt-get install -y nodejs 
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get install apt-transport-https
RUN apt-get update && apt-get install -y yarn
RUN apt-get install -y libstdc++-5-dev

# Get psql
RUN apt-get install -y postgresql-client

# Get tippecanoe
RUN apt-get install -y libprotobuf-dev protobuf-compiler libsqlite3-dev && git clone https://github.com/mapbox/tippecanoe.git && cd tippecanoe && make && make install

# Install node modules
ENV NPM_CONFIG_LOGLEVEL=warn
ADD package.json /tmp/package.json
RUN cd /tmp && yarn
RUN mkdir -p /opt/app && cp -a /tmp/node_modules /opt/app/

RUN node -v 

# Change to app directory
WORKDIR /opt/app
ADD . /opt/app

CMD ["node", "/opt/app/index.js"]
