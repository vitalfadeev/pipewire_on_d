#!/bin/bash
gcc -o volume-monitor volume-monitor.c $(pkg-config --cflags --libs libpipewire-0.3)
