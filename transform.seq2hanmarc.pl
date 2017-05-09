#!usr/bin/env perl

use strict;
use warnings;
no warnings 'uninitialized';

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

# Hashes for storing data
my %f245a;
my %f351c;
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

    my $f245a = marc_map($data, '245a');
    my $f351c = marc_map($data, '351c');
    my $f490i = marc_map($data, '490i');
    my $f490v = marc_map($data, '490v');
    my $f490w = marc_map($data, '490w');
    my $f852a = marc_map($data, '852a');
    my $f907g = marc_map($data, '907g');
    my $f909f = marc_map($data, '909f');

    # If field 490 not present, use field 773
    $f490i = marc_map($data, '773j') unless $f490i;
    $f490v = marc_map($data, '773g') unless $f490v;
    $f490w = marc_map($data, '773w') unless $f490w;

    # Insert leading zeros for system numbers
    if ($f490w) {
        $f490w = sprintf("%09d", $f490w);
    }

    $f245a{$sysnum} = $f245a;
    $f351c{$sysnum} = $f351c;
    $f490w{$sysnum} = $f490w;
    $f490i{$sysnum} = $f490i;
    $f490v{$sysnum} = $f490v;
    $f852a{$sysnum} = $f852a;
    $f907g{$sysnum} = $f907g;
    $f909f{$sysnum} = $f909f;

});

my $all = 0;
my $gruen = 0;
my $orange = 0;

# Second importer: Modify records
$importer2->each(sub {
    $all += 1;
    my $data = $_[0];
    
    # Insert system number in field 001
    my $sysnum = $data->{'_id'};
    $data = marc_add($data, '001', a => $sysnum);

    # Remove existing fields 490 and 773
    $data = marc_remove($data, '490');
    $data = marc_remove($data, '773');

    # Modify and insert new field 490
    unless ($f351c{$sysnum} =~ /(Hauptabteilung|Abteilung|Bestand)/) {
        my $parent = $f490w{$sysnum};
        my ($topid, $toptitle) = addparents($parent);
        $data = marc_add($data, '490', a => $f245a{$parent}, v => $f490v{$sysnum}, i => $f490i{$sysnum}, w => $f490w{$sysnum}, x => $toptitle, y => $topid);
    }
    
    # Remove records with hide_this codes or specific archival levels 
    unless (($f909f{$sysnum} =~ /hide\_this/) ||($f351c{$sysnum} =~ /(Hauptabteilung|Abteilung|Bestand)/)) {
        if ($f852a{$sysnum} =~ /(Basel|Bern)/) {
            # Add records for swissbib orange
            $exporter2->add($data);
            $orange += 1;
        } else {
            # Add records for swissbib green (everything except orange)
            $exporter1->add($data);
            $gruen += 1;
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

    my $toptitle;
    my $topid;

    if ($sysnum && ($sysnum != '000000000')) {

        $topid = $sysnum;
        $toptitle = $f245a{$sysnum};

        my $parent = $f490w{$sysnum};

        unless ($f351c{$sysnum} =~ /(Abteilung|Hauptabteilung|Bestand)/) {
            ($topid, $toptitle) = addparents($parent);
        }
    }
    return ($topid, $toptitle);
};