#!/usr/bin/env perl
use 5.012;
use warnings;
use FindBin qw($RealBin);
use lib "$RealBin/../lib/";
use Qiime2::Artifact;
use Term::ANSIColor qw(:constants);
use Data::Dumper;
use JSON::PP;
use Data::Structure::Util qw/unbless/;

 $Data::Dumper::Indent = 1;
 $Data::Dumper::Terse = 1;
use Getopt::Long;
  my $opt_dump;

my $_opt = GetOptions(
  'd|dump'  => \$opt_dump,

);

my $file;
if (-e "$ARGV[0]") {
  $file = $ARGV[0];
} elsif (-e "$RealBin/../example/table.qza") {
  $file = "$RealBin/../example/table.qza";
} else {
  die "Specify artifact\n";
}
my $artifact = Qiime2::Artifact->new( { filename => "$file", debug => 1 });


if ($opt_dump) {

  say serialize($artifact);

}  else {

  say 'FILENAME: [',  $artifact->{filename}, ']';
  say 'ID:       [',$artifact->id, ']';

  say 'ORIGINAL: [',$artifact->{imported}, ']';
  say 'PARENTS:  [',$artifact->{parents}, ']';
  s
  say GREEN,  Dumper $artifact->{ancestry};
  say RESET '';
}



sub serialize {
  my $json = JSON::PP->new->ascii->pretty->allow_nonref;
  my $obj = shift;
  my $class = ref $obj;
  unbless $obj;
  my $rslt = $json->encode($obj);
  bless $obj, $class;
  return $rslt;
}


sub deserialize {
  my ($json, $class) = @_;
  my $obj = decode_json($json);
  return bless($obj, $class);
}
