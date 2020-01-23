use strict;
use warnings;
use Qiime2::Artifact;
use Test::More;
use Data::Dumper;
use FindBin qw($Bin);

my $file = "$Bin/../data/non_artifact.zip";
SKIP: {
	skip "missing input file" unless (-e "$file");
  eval {
   print STDERR "Not a valid artifact $file:\n";
	 my $artifact = Qiime2::Artifact->new({ filename => "$file" });
   print STDERR "\n";
  };

  ok($@, "$file is not an artifact");

}

done_testing();