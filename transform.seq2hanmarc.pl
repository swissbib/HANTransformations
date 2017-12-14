#!usr/bin/env perl

use strict;
use warnings;

# Data::Dumper for debugging
use Data::Dumper;

die "Argumente: $0 Input-Dokument (alephseq), Output Non-Orange Output Orange\n" unless @ARGV == 3;

# Unicode support inside the Perl script
use utf8;
# Unicode support for Output
binmode STDOUT, ":utf8";

# Catmandu modules
use Catmandu::Importer::MARC::ALEPHSEQ;
use Catmandu::Exporter::MARC;
use Catmandu::Fix::Inline::marc_map qw(:all);
use Catmandu::Fix::Inline::marc_add qw(:all);
use Catmandu::Fix::marc_remove as => 'marc_remove';

# Importer for initial reading of the Aleph sequential file 
my $importer1 = Catmandu::Importer::MARC::ALEPHSEQ->new(file => $ARGV[0]);
# Importer for second reading of the Aleph sequential file 
my $importer2 = Catmandu::Importer::MARC::ALEPHSEQ->new(file => $ARGV[0]);

# Exporter for output for swissbib green (everything except Basel Bern)
my $exporter1 = Catmandu::Exporter::MARC->new(file => $ARGV[1], type => "XML", pretty => '1');
# Exporter for output for swissbib orange (only Basel Bern)
my $exporter2 = Catmandu::Exporter::MARC->new(file => $ARGV[2], type => "XML", pretty => '1');

# Log-file for not valid institutions in 852$a
my $logfile = './institution_notvalid.log';
open(my $log, '>:encoding(UTF-8)', $logfile) or die "Could not open file '$logfile' $!";

# Hashes for storing data
my %f008;
my %f245a;
my %f351c;
my %f490a;
my %f490w;
my %f490i;
my %f490v;
my %f852a;
my %f907g;
my %f909f;

# First importer: Reading in all necessary data in hashes
$importer1->each(sub {

    my $data = $_[0];
    my $sysnum = $data->{'_id'};

    my $f008  = marc_map($data, '008');
    my $f245a = marc_map($data, '245a');
    my $f351c = marc_map($data, '351c');
    my $f490a = marc_map($data, '490a');
    my $f490i = marc_map($data, '490i');
    my $f490v = marc_map($data, '490v');
    my $f490w = marc_map($data, '490w');
    # 852 can be repeated, therefore we read it into an array and use only the first array element.
    my @f852a = marc_map($data, '852[  ]a');
    my $f907g = marc_map($data, '907g');
    my $f909f = marc_map($data, '909f');

    # If field 490 not present, use field 773
    $f490a = marc_map($data, '773a') if $f490a eq "";
    $f490i = marc_map($data, '773j') if $f490i eq "";
    $f490v = marc_map($data, '773g') if $f490v eq "";
    $f490w = marc_map($data, '773w') if $f490w eq "";

    # Insert leading zeros for system numbers
    if ($f490w) {
        $f490w = sprintf("%09d", $f490w);
    }

    $f008{$sysnum}  = $f008;
    $f245a{$sysnum} = $f245a;
    $f351c{$sysnum} = $f351c;
    $f490w{$sysnum} = $f490w;
    $f490i{$sysnum} = $f490i;
    $f490v{$sysnum} = $f490v;
    $f852a{$sysnum} = $f852a[0];
    $f907g{$sysnum} = $f907g;
    $f909f{$sysnum} = $f909f;

});

my $all = 0;
my $gruen = 0;
my $orange = 0;

# Second importer: Modify records
$importer2->each(sub {
    my $data = $_[0];
    
    # Insert system number in field 001
    my $sysnum = $data->{'_id'};
    $data = marc_add($data, '001', a => $sysnum);

    # Replace all random characters in the 008 date fields with "u"
    unless (substr($f008{$sysnum},7,4)  =~ /[0-2][0-9]{3}/) { substr($f008{$sysnum},7,4) = 'uuuu' }
    unless (substr($f008{$sysnum},11,4) =~ /[0-2][0-9]{3}/) { substr($f008{$sysnum},11,4) = 'uuuu' } 

    my $record = $data->{'record'};
    for my $var (@$record) {
       if ($var->[0] eq '008') {
           $var->[4] = $f008{$sysnum}
       }
    }

    # Remove existing fields 490 and 773
    $data = marc_remove($data, '490');
    $data = marc_remove($data, '773');

    # Modify and insert new field 490
    my $parent = $f490w{$sysnum};

    if ($f351c{$parent} =~ /(Hauptabteilung|Abteilung)/) {
        $data = marc_add($data, '490', a => $f245a{$parent}, v => $f490v{$sysnum}, i => $f490i{$sysnum});
    } elsif (!($f490w{$sysnum})) {
        $data = marc_add($data, '490', a => $f490a{$sysnum}, v => $f490v{$sysnum}, i => $f490i{$sysnum});
    } else {
        my ($topid, $toptitle) = addparents($parent);
        $data = marc_add($data, '490', a => $f245a{$parent}, v => $f490v{$sysnum}, i => $f490i{$sysnum}, w => $f490w{$sysnum}, x => $toptitle, y => $topid);
    }

    # Remove records with hide_this codes or specific archival levels 
    unless (( defined $f909f{$sysnum} && $f909f{$sysnum}  =~ /hide\_this/) ||( defined $f351c{$sysnum} && $f351c{$sysnum} =~ /(Hauptabteilung|Abteilung)/)) {
        if ($f852a{$sysnum} =~ /(^Basel UB$|^Basel UB Wirtschaft - SWA$|^Solothurn ZB$|^Bern Gosteli-Archiv$|^Bern UB Medizingeschichte: Rorschach-Archiv$|^Bern UB Schweizerische Osteuropabibliothek$|^Bern UB Archives REBUS$)/) {
            # Add records for swissbib orange
            $exporter2->add($data);
            $orange += 1;
            $all += 1;
        } elsif ($f852a{$sysnum} =~ /(^KB Appenzell Ausserrhoden$|^KB Thurgau$|^Luzern ZHB$|^St. Gallen KB Vadiana$|^St. Gallen Stiftsbibliothek$|^Zofingen SB$)/) {
            # Add records for swissbib green (everything except orange)
            $exporter1->add($data);
            $gruen += 1;
            $all += 1;
        } else {
            print $log "Not a HAN-Institution: $f852a{$sysnum} ($sysnum) \n";
        }
    }
});

$exporter1->commit;
$exporter2->commit;

print "All: " . $all . " Non-Orange: " . $gruen . " Orange: " . $orange . "\n";
exit;
# Subroutine for finding the system number of the topmost record of an archival hierarchy (iterates recursively through the whole hierarchy)
sub addparents{
    my $sysnum = $_[0];

    my $topid = $sysnum;
    my $toptitle = $f245a{$sysnum};
    my $parent = $f490w{$sysnum};

    unless (($f351c{$parent} =~ /(Hauptabteilung|Abteilung)/) || !($f490w{$sysnum})) {
        ($topid, $toptitle) = addparents($parent);
    }
    return ($topid, $toptitle);
};
