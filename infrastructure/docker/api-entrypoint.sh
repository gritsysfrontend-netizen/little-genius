#!/bin/sh
set -eu
./node_modules/.bin/prisma migrate deploy
node dist/src/seed.js
exec node dist/src/server.js
