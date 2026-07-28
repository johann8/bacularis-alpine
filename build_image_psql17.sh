#!/bin/bash

# set variables
D_IMAGE_VERSION=6.4.0.1
D_IMAGE_TAG=alpine
BASE_IMAGE=alpine:3.24

BACULARIS_VERSION=6.4.0
BACULA_VERSION=15.0.3-r0
PHP_VERSION=85
POSTGRES_VERSION=17


# create build docker image
#docker build -f ./Dockerfile -t johann8/bacularis:${D_IMAGE_VERSION}-alpine . 2>&1 | tee ./build.log
docker build \
  --build-arg=BASE_IMAGE=${BASE_IMAGE} \
  --build-arg=BACULARIS_VERSION=${BACULARIS_VERSION} \
  --build-arg=BACULA_VERSION=${BACULA_VERSION} \
  --build-arg=PHP_VERSION=${PHP_VERSION} \
  --build-arg=POSTGRES_VERSION=${POSTGRES_VERSION} \
  --platform=linux/amd64 \
  --tag=johann8/bacularis:${D_IMAGE_VERSION}-${D_IMAGE_TAG}-psql${POSTGRES_VERSION} \
  --file=./Dockerfile . 2>&1 | tee ./build.log

# check result
_BUILD=$?

# if build successful - create docker image tag
if ! [ ${_BUILD} = 0 ]; then
   echo "ERROR: Docker Image build was not successful"
   exit 1
else
   echo "Docker Image build successful"
   docker images -a
   docker tag johann8/bacularis:${D_IMAGE_VERSION}-${D_IMAGE_TAG}-psql${POSTGRES_VERSION} johann8/bacularis:latest-${D_IMAGE_TAG}-psql${POSTGRES_VERSION}
fi

#push image to docker hub
if [ ${_BUILD} = 0 ]; then
   echo "Pushing docker images to dockerhub..."
   docker push johann8/bacularis:latest-${D_IMAGE_TAG}-psql${POSTGRES_VERSION}
   docker push johann8/bacularis:${D_IMAGE_VERSION}-${D_IMAGE_TAG}-psql${POSTGRES_VERSION}
   _PUSH=$?
   docker images -a |grep bacularis
fi


#delete build local
if [ ${_PUSH=} = 0 ]; then
   echo "Deleting docker images..."
   docker rmi johann8/bacularis:latest-${D_IMAGE_TAG}-psql${POSTGRES_VERSION}
   docker rmi johann8/bacularis:${D_IMAGE_VERSION}-${D_IMAGE_TAG}-psql${POSTGRES_VERSION}
   docker images -a
fi

# Delete none images
# docker rmi $(docker images --filter "dangling=true" -q --no-trunc)
