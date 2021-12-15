#!/bin/bash
set -e

#the environmental variable thing apparently can't be set when making the container
export IGDATA=/usr/local/share/igblast
bracer ${@:1}
