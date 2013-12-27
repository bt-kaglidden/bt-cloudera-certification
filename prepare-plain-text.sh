#!/bin/bash -ue
# Prepare text for use with the config/*plain-text-morphlines.conf configurations.
#
mkdir -p $2
find $1 -maxdepth 1 -type f  ! -name '.*' | while read -r FILE; do
  BASENAME=$(basename $FILE)
  echo "File-Name: <$BASENAME>" | cat - $FILE > x && mv x $2/$BASENAME
done
