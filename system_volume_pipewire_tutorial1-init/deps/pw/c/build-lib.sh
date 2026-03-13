#!/bin/sh
NAME=tutorial
gcc -c ${NAME}.c `pkg-config --cflags-only-I --libs-only-l libpipewire-0.3`
ar rc ../lib/lib${NAME}.a ${NAME}.o
