use strict;
use warnings;
use Qiime2::Artifact;
use Test::More;
use Data::Dumper;
use FindBin qw($Bin);

my $file = "$Bin/../data/sample_metadata.tsv";
SKIP: {
		system('unzip > /dev/null');
		skip "unzip not found, but a path could be specified when creating the instance of Qiime2::Artifact\n" if ($?);


	  eval {
	   print STDERR "Raise exception:\n";
		 my $artifact = Qiime2::Artifact->new({ filename => "404/file_not_found" });
	   print STDERR "\n";
	  };

	ok($@, "Crashed trying to open a file that does not exist");

	
	skip "missing input file" unless (-e "$file");

  eval {
   print STDERR "Raise exception:\n";
	 my $artifact = Qiime2::Artifact->new({ filename => "$file" });
   print STDERR "\n";
  };

  ok($@, "$file is not an artifact");

}

done_testing();
