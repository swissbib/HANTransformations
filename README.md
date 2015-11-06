# HANTransformations
Transformations (XSLT) and basic workflow scripts to prepare HAN-data for indexing in swissbib

## Installation
The following scripts need to be saved in the HANTransformations root directory:
* workflow.HAN.sh: shell script that controls the main workflow. It calls the two scripts consecutively: 
 * transform.han2sbmarc.sh (step 1)
 * transform.into.1.line.sh (step 2)
* transform.into.1.line.pl: perl script to flatten the records into one line (called by step 2)

The xslt-script HAN.Bestand.xslt needs to be saved in: ```HANTransformations/xslt```

An XML parser needs to be saved in: ```HANTransformations/libs```

We use saxon, e.g. saxon9pe.jar, along with the license

## Directories
* Input directory step 1: HANTransformations/raw.hanmarc; contains data in MarcXML format
* Output directory step 1: HANTransformations/out.swissbib-MARC
* Input directory step 2: HANTransformations/out.swissbib-MARC
* Output directory step 2: HANTransformations/out.swissbib-MARC-1line