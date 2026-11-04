#! /bin/bash

# NOTE: first log in requires updating sudoers for default user.
#
# log in as root user:
# $ docker exec -it name_of_container bash
#
# edit sudoers file
# EDITOR=nano visudo
#
# uncomment wheel

echo "looking for existing ttya container"
CONTAINER_ID=$(docker ps | grep ttya | awk '{print $1}')

if [[ -z "$CONTAINER_ID" ]]; then
  echo "starting ttya container"
  docker compose up -d
  CONTAINER_ID=$(docker ps | grep ttya | awk '{print $1}')
fi

echo "opening tty"
docker exec --interactive --tty --user default --workdir /home/default $CONTAINER_ID bash
