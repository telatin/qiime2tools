#!/usr/bin/env perl
# Combines biom file extracted from artifact and converted to tsv with taxonomy

use 5.012;
use warnings;
use Getopt::Long;
use File::Basename;
my $BASENAME = basename($0);

my ($otu_file, $taxonomy_file) = @ARGV;
my $opt_verbose;
my $_opt = GetOptions(
    'verbose' => \$opt_verbose,
);

if (not defined $taxonomy_file) {
    say<<END;

  Usage:
  $BASENAME [options] OTU.tsv taxonomy.tsv

END
}

die " FATAL ERROR:\n Unable to find OTU file <$otu_file>\n" if (! -e "$otu_file");
die " FATAL ERROR:\n Unable to find OTU file <$taxonomy_file>\n" if (! -e "$taxonomy_file");

open (my $OTU, '<', "$otu_file") || die " FATAL ERROR:\n Unable to open <$otu_file>\n";
open (my $TAX, '<', "$taxonomy_file") || die " FATAL ERROR:\n Unable to open <$taxonomy_file>\n";

my $c = 0;
my %taxonomy = ();

while (my $line = readline($TAX) ) {
    chomp($line);
    $c++;
    my ($featID, $taxon, $confidence) = split /\t/, $line;
    if ($c == 1) {
        #Feature ID       Taxon   Confidence
        say STDERR "*** WARNING: Expected header not found in line 1 of <$taxonomy_file>:\n$featID != 'Feature ID', $taxon ne 'Taxon'\n"
            if ($featID ne 'Feature ID' or $taxon ne 'Taxon');
        next;
    } else {
        $taxonomy{$featID} = $taxon;
    }
}
close $TAX;
vprint("$c lines loaded from $taxonomy_file");

my $j = 0;
while (my $line = readline($OTU) ) {
    $j++;
    chomp($line);
    my @fields = split /\t/, $line;
    if ($j == 1) {
        say STDERR "*** WARNING: Expected header not found in line 1 of <$otu_file>:\nFound: $fields[0]\nExpecting: #OTU ID ...\n"
            if ($fields[0] ne '#OTU ID');
        print "$line\ttaxonomy\n";
    } else {
        print "$line\t$taxonomy{$fields[0]}\n";
    }
}
if ($j == $c) {
 vprint("$j lines loaded from $otu_file");
} else {
 print "*** WARNING: Expecting $c lines, but $j lines found in $otu_file\n";
}

sub vprint {
    say STDERR $_[0] if ($opt_verbose);
}