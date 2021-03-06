#!/bin/bash

# Script that controls the main workflow

BASEDIR=/opt/scripts/HANTransformations/
source $BASEDIR/han_transformations.conf

DO_DOWNLOAD=1
DO_CATMANDU=1
DO_XSLT=1
DO_FINISH=1
DO_UPLOAD=1
DO_EMAIL=1

DATE=`date +%Y%m%d`
LOG=$BASEDIR/log/han_transformations_$DATE.log
INFOMAIL=$BASEDIR/han_transformations_infomail.txt

if [ "$DO_DOWNLOAD" == "1" ]; then
   echo "Downloading Aleph-Sequential" >> $LOG
   #$BASEDIR/download.dsv05.sequential.sh
   #mv $BASEDIR/dsv05.seq $BASEDIR/raw.hanseq/
   cp /opt/data/dsv05/dsv05.seq $BASEDIR/raw.hanseq/ &>> $LOG 
fi

if [ "$DO_CATMANDU" == "1" ]; then
    echo "Transforming Aleph-Sequential into HAN-Marc" >> $LOG
    perl $BASEDIR/transform.seq2hanmarc.pl $BASEDIR/raw.hanseq/dsv05.seq $BASEDIR/raw.hanmarc/gruen.xml $BASEDIR/raw.hanmarc/orange.xml >> $LOG 
fi

if [ "$DO_XSLT" == "1" ]; then
    $BASEDIR/transform.han2sbmarc.sh $BASEDIR HAN &>> $LOG
fi

if [ "$DO_FINISH" == "1" ]; then
    $BASEDIR/transform.into.1.line.sh $BASEDIR &>> $LOG
fi
if [ "$DO_UPLOAD" == "1" ]; then
    echo "Uploading files to swissbib-Server" >> $LOG
    scp $BASEDIR/out.swissbib-MARC-1line/gruen_marcxml.format.xml swissbib@sb-dp1.swissbib.unibas.ch:/swissbib_index/solrDocumentProcessing/FrequentInitialPreProcessing/data/format_archivaldata/ &>> $LOG
    scp $BASEDIR/out.swissbib-MARC-1line/orange_marcxml.format.xml swissbib@sb-dp1.swissbib.unibas.ch:/swissbib_index/solrDocumentProcessing/FrequentInitialPreProcessing/data/format_archivaldata/ &>> $LOG 
fi

if [ "$DO_EMAIL" == "1" ]; then
    cat $LOG | mailx -a "From:aleph-ub@unibas.ch" -s "Logfile: HAN-Daten fuer swissbib vom $DATE generiert" $MAIL_EDV
    cat $INFOMAIL | mailx -a "From:aleph-ub@unibas.ch" -s "Infomail: HAN-Daten fuer swissbib vom $DATE generiert" $MAIL_HAN
fi
