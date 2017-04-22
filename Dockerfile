FROM node:6.10
LABEL maintainer="Marc Farra <marc@developmentseed.org>"

# Get psql
RUN wget -O - http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | apt-key add - && echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" > /etc/apt/sources.list.d/pgdg.list && apt-get update && apt-get install -y postgresql-client-9.4

# Get tippecanoe
RUN apt-get install -y libprotobuf-dev protobuf-compiler libsqlite3-dev && git clone https://github.com/mapbox/tippecanoe.git && cd tippecanoe && make && make install

# Install node modules
ENV NPM_CONFIG_LOGLEVEL=warn
ADD package.json /tmp/package.json
RUN cd /tmp && yarn
RUN mkdir -p /opt/app && cp -a /tmp/node_modules /opt/app/

# Change to app directory
WORKDIR /opt/app
ADD . /opt/app

CMD ["node", "/opt/app/index.js"]
