#!/bin/bash

# set variables
D_IMAGE_VERSION=5.11.1
#PG_VERSION=psql16

# create build docker image
#docker build -f ./Dockerfile -t johann8/bacularis:${D_IMAGE_VERSION}-alpine . 2>&1 | tee ./build.log
docker build \
  --build-arg=BACULARIS_VERSION=5.11.0 \
  --build-arg=BACULA_VERSION=15.0.3-r0 \
  --build-arg=POSTGRES_VERSION=16 \
  --platform=linux/amd64 \
  --tag=johann8/bacularis:${D_IMAGE_VERSION}-alpine \
  --file=./Dockerfile . 2>&1 | tee ./build.log

_BUILD=$?

# if build successful - create docker image tag
if ! [ ${_BUILD} = 0 ]; then
   echo "ERROR: Docker Image build was not successful"
   exit 1
else
   echo "Docker Image build successful"
   docker images -a 
   docker tag johann8/bacularis:${D_IMAGE_VERSION}-alpine johann8/bacularis:latest-alpine
fi

# For debug only
#exit 0

#push image to dockerhub
if [ ${_BUILD} = 0 ]; then
   echo "Pushing docker images to dockerhub..."
   docker push johann8/bacularis:latest-alpine
   docker push johann8/bacularis:${D_IMAGE_VERSION}-alpine
   _PUSH=$?
   docker images -a |grep bacularis
fi


#delete build
if [ ${_PUSH=} = 0 ]; then
   echo "Deleting docker images..."
   docker rmi johann8/bacularis:latest-alpine
   #docker images -a
   docker rmi johann8/bacularis:${D_IMAGE_VERSION}-alpine
   docker images -a
fi

# Delete none images
# docker rmi $(docker images --filter "dangling=true" -q --no-trunc)
