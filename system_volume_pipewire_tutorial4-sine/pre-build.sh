#!/bin/bash
echo "Pre-build..."
CDIR=`pwd`
cd deps/pw/c/
./build-lib.sh
cd $CDIR
