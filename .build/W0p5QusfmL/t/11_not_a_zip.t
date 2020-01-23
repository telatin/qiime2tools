use strict;
use warnings;
use Qiime2::Artifact;
use Test::More;
use Data::Dumper;
use FindBin qw($Bin);

my $file = "$Bin/../data/sample_metadata.tsv";
SKIP: {
	skip "missing input file" unless (-e "$file");
	my $artifact = Qiime2::Artifact->new({ filename => "$file" });

}

done_testing();
