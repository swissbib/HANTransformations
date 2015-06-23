#Script purpose: call perl script to flatten the lines

basedir=$1

inputdir=$basedir/out.swissbib-MARC
outputdir=$basedir/out.swissbib-MARC-1line

plfile=$basedir/transform.into.1.line.pl

echo "start perl transformation to flatten records into one single line"

for datei in $inputdir/*.xml
do

	filename=`basename ${datei} .xml`

	#suffix format.xml for the file name is necessary for the next steps
	echo  "transformation of "$datei "into "$filename.format.xml 
	perl $plfile $datei  > $outputdir/$filename.format.xml
	
done