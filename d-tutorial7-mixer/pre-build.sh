#!/bin/bash
echo "Pre-build..."
CDIR=`pwd`
cd deps/spa_wrapper/c/
./build-lib.sh
cd $CDIR
