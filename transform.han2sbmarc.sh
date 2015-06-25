# Script to process files with HAN data (HAN-Marc) with an xslt-transformation to get MARC21 records

basedir=$1

inputdir=$1/raw.hanmarc
outputdir=$1/out.swissbib-MARC
xslt=$basedir/xslt/HAN.Bestand.xslt
output=HAN.marc21.nr
cp=$1/libs/saxon9.jar
#institutioncode=$2

nr=1

echo "start HAN-Marc -> Marc21 transformation"

for datei in $inputdir/*.xml
do

	echo "file: "$datei
	java -Xms2024m -Xmx2024m  -cp $cp  net.sf.saxon.Transform -s:$datei -xsl:$xslt -o:$outputdir/$output$nr.xml
	nr=$(($nr+1))

done