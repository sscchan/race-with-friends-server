#!/bin/bash

if [ "$DEPLOYTOSTAGING" = "TRUE" ]; then

  # Tag the container images to use the namespace correspond to the team's Docker hub account
  docker-compose build $1
  docker tag racewithfriendsserver_$1:latest hr52elves/$1:latest    

  # Login to Docker Hub
  docker login -e $DOCKER_EMAIL -u $DOCKER_USER -p $DOCKER_PASS

  # Push the images to Docker Hub
  docker push hr52elves/$1:latest

  echo "stopping running application"
  ssh $DEPLOY_USER@$DEPLOY_HOST "cd /home/ubuntu/app/; docker-compose stop $1;"
  ssh $DEPLOY_USER@$DEPLOY_HOST "cd /home/ubuntu/app/; docker-compose rm -f $1;"

  echo "pulling latest version of the code"
  ssh $DEPLOY_USER@$DEPLOY_HOST "docker pull hr52elves/$1:latest"

  echo "starting the new version"
  # Copy over new deploy specific docker-compose file
  scp -r deploy-machine-docker-compose.yml $DEPLOY_USER@$DEPLOY_HOST:/home/ubuntu/app/docker-compose.yml

  # Copy over PostgreSQL testdb initialization configuration files to Deploy Server
  scp -r ./RunDB/init_testdb.sql $DEPLOY_USER@$DEPLOY_HOST:/home/ubuntu/app/RunDB/init_testdb.sql

  ssh $DEPLOY_USER@$DEPLOY_HOST 'cd /home/ubuntu/app/; docker-compose up -d'
  ssh $DEPLOY_USER@$DEPLOY_HOST 'cd /home/ubuntu/app/; docker images -q --filter "dangling=true" | xargs docker rmi'  

  echo "success!"

  exit 0  
fi