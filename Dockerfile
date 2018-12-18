FROM ubuntu:16.04

ENV DEBIAN_FRONTEND noninteractive

# Get node and yarn
RUN apt-get update -y
RUN apt-get install -y build-essential software-properties-common curl git mercurial && add-apt-repository ppa:ubuntu-toolchain-r/test
RUN apt-get update -y
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash -
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

# Get AWS CLI and Mapbox CLI
# The Ubuntu Trusty version of `requests` is insufficient for `mapboxcli` uploads
RUN apt-get install -y python-pip && pip install --upgrade requests && pip install awscli && npm install -g mapbox-upload geojson-stream-merge

# Get geospatial libraries necessary for routability code
RUN apt-get install -y \
	python-dev \
	python-gdal \
	python-tk \
	gdal-bin \
	libspatialindex-dev \
	libfreetype6-dev \
	libpng12-dev \
	libgdal-dev \
	libblas-dev \
	liblapack-dev \
	libatlas-base-dev \
	gfortran \
	zip
ADD Network_Cleaning/requirements.txt /tmp/requirements.txt
RUN pip install -U setuptools
RUN hg clone http://bitbucket.org/chris_forbes/descartes && cd descartes && hg checkout fix-compatability-with-matplotlib-3.0+ && python setup.py install
RUN pip install -r /tmp/requirements.txt

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
