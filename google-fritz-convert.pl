#!/usr/bin/perl
use XML::Writer;
use strict;
use warnings;
use Text::CSV;
use Data::Dumper;
use utf8;
my %phonebook = ();
my @phonentries = ();
my $epoc = time();
my $file = $ARGV[0] or die "Need to get CSV file on the command line\n";
my $csv  = Text::CSV->new(
    {
        binary    => 1,
        auto_diag => 1,
        sep_char  => ','    # not really needed as this is the default
    }
);
my $sum = 0;
open( my $data, '<:encoding(utf8)', $file )
  or die "Could not open '$file' $!\n";
my $fields = $csv->getline($data);
while (my ($index, $element) = each(@$fields)){
  if ($element =~ m/Phone \d - Value/ ){
    push (@phonentries, $index);
#    print "gefunden index $index\n";
  }
}
while ( $fields = $csv->getline($data) ) {
  $phonebook{"@$fields[0] @$fields[2]"} = "";
  foreach my $pent (@phonentries){
    my $field = @$fields[$pent];
    if (length($field) >= 3){
      my $line = @$fields[$pent];
      my @phnumbers = split (/\:\:\:/, $line);
      foreach my $pnumber (@phnumbers){
          if ($pnumber =~ m/\d{3,}/){
            $pnumber =~ s/\s//g;
            $pnumber =~ s/\-//g;
            # print "@$fields[0] @$fields[2] $pnumber\n";
            $phonebook{"@$fields[0] @$fields[2]"} = $phonebook{"@$fields[0] @$fields[2]"} . " $pnumber"
        }
      }
    }
  }
}


if ( not $csv->eof ) {
    $csv->error_diag();
}
close $data;

my $writer = XML::Writer->new(OUTPUT => 'self', DATA_MODE => 1, DATA_INDENT => 2, );
$writer->xmlDecl('UTF-8');
$writer->startTag('phonebooks');
$writer->startTag('phonebook');
my $i=0;

foreach my $contact_key (keys %phonebook){
  my $phonenumbers = $phonebook{$contact_key};
  $i++;

  $writer->startTag('contact');
  $writer->startTag('person');
  $writer->startTag('realName');
  my $contact = $contact_key;
  chomp($contact);
  $writer->characters($contact);
  $writer->endTag('realName');
  $writer->endTag('person');

  $writer->startTag('telephony', nid => "1");
  foreach my $phonenumber (split(/ /,$phonenumbers)) {
    next if ($phonenumber eq "");
    $writer->startTag('number', type => "home", id=>"0");
    $writer->characters($phonenumber);
    $writer->endTag('number');
  }

  $writer->endTag('telephony');
  $writer->startTag('services');
  $writer->endTag('services');
  $writer->startTag('setup');
  $writer->endTag('setup');
  $writer->startTag('features', 'doorphone' => "0");
  $writer->endTag('features');
  $writer->startTag('mod_time');
  $writer->characters($epoc);
  $writer->endTag('mod_time');
  $writer->startTag('uniqueid');
  $writer->characters($i);
  $writer->endTag('uniqueid');
  $writer->endTag('contact');
}

$writer->endTag('phonebook');
$writer->endTag('phonebooks');

my $xml = $writer->end();
print $xml;

open(my $fh, '>:encoding(UTF-8)', "Telefonbuch-aus-google.xml");
print $fh $xml;
close($fh);
