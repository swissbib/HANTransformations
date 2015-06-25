#!/bin/sh

# Script that controls the main workflow

basedir=$PWD

$basedir/transform.han2sbmarc.sh $basedir HAN
#$basedir/remove.marc.namespaces.sh $basedir
#$basedir/transform.into.1.line.sh $basedir