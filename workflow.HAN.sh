#!/bin/bash

# Script that controls the main workflow

basedir=$PWD

DO_DOWNLOAD=0
DO_CATMANDU=1
DO_XSLT=0
DO_FINISH=0

if [ "$DO_DOWNLOAD" == "1" ]; then
   echo "Downloading Aleph-Sequential"
   $basedir/download.dsv05.sequential.sh
   mv $basedir/dsv05.seq $basedir/raw.hanseq/
fi

if [ "$DO_CATMANDU" == "1" ]; then
    echo "Transforming Aleph-Sequential into HAN-Marc"
    perl transform.seq2hanmarc.pl $basedir/raw.hanseq/dsv05.seq $basedir/raw.hanmarc/gruen.xml $basedir/raw.hanmarc/orange.xml
fi

if [ "$DO_XSLT" == "1" ]; then
$basedir/transform.han2sbmarc.sh $basedir HAN 
fi

if [ "$DO_FINISH" == "1" ]; then
$basedir/transform.into.1.line.sh $basedir
fi
