#!/bin/sh

echo "PORT is on $PORT"

export NODE_ENV=production

yarn start -p $PORT
