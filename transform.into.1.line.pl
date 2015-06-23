#!/usr/bin/perl


use strict;

sub ltrim($);

my $first_line = '<collection>';
my $start_record = '<record';
my $end_record = '</record>';
my $leerzeile = '^$';
my $last_line = '</collection>';
my $xml_declaration = '<\?xml';



my $line_to_write = "";
my $in_declaration_section = 0;
my $in_record_section = 0;



while (<>) {
   
   if (/$leerzeile/) {
   	  next;
   }elsif (/($xml_declaration|$first_line|$last_line)/) {
      writeline($_);
      next;
   } elsif (/$start_record/) {
   	  chomp;
   	  $line_to_write =  ltrim($_);
   	  $in_record_section = 1;	
      #$line_to_write .=  $_;
   } elsif (/$end_record/) {
   	  chomp;
   	  $line_to_write .=  ltrim($_);
   	  $line_to_write .=  "\n";
   	  $in_record_section = 0;
   	  writeline($line_to_write);	
      next;
   	}	 else {
   	  chomp;
      $line_to_write .= ltrim($_);
      
   	}   
}


sub writeline {
   
   print $_[0]; 
}

sub ltrim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	return $string;
}

