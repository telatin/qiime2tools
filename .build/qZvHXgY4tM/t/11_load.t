use strict;
use warnings;
use Qiime2::Artifact;
use Test::More;
use FindBin qw($Bin);

my $file = "$Bin/../data/table.qza";
my $id   = 'd27b6a68-5c6e-46d9-9866-7b4d46cca533';
print "$file\n";

SKIP: {
	skip "missing input file" unless (-e "$file");
	my $artifact = $Qiime2::Artifact->new({ filename => "$file" });
	ok($artifact->{loaded} == 1, 'Artifact was loaded');
	ok($artifact->{id} == "$id", 'Artifact has correct ID ' . $id);
}

done_testing();
