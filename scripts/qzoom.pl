#!/usr/bin/env perl

use v5.16;
use Pod::Usage;
use Getopt::Long;
use File::Basename;
use YAML::Tiny;
use Data::Dumper;
use Term::ANSIColor qw(:constants);
our $AUTHOR  = 'Andrea Telatin';
our $VERSION = '1.02';
our $this_program = basename($0);
our $biom_found = 0;
my ($opt_cite,
	$opt_help, 
	$opt_version, 
	$opt_debug,
	$opt_data,
	$opt_citation_file,
	$opt_extract,
	$opt_info,
	);
my $opt_outdir =  "./";
my $result = GetOptions(
	'd|data'      => \$opt_data,
	'i|info'      => \$opt_info,
	'c|cite'      => \$opt_cite,
	'b|bibtex=s'  => \$opt_citation_file,

 	'x|extract'   => \$opt_extract,
 	'o|outdir=s'  => \$opt_outdir,

	'debug'       => \$opt_debug,
	'v|version'   => \$opt_version,
	'h|help'      => \$opt_help,
);
init();

usage() if not defined $ARGV[0];

$opt_info = 1 if (!$opt_cite and !$opt_data and !$opt_extract);
foreach my $opt_filename (@ARGV) {

	our $artifact = getArtifact($opt_filename);
	our $output;

	debug(" - Loading <$opt_filename>");
	if ( ! -f "$opt_filename") {
		say STDERR " - Skipping \"$opt_filename\": not found";
		next;
	}
	 

	if (defined $opt_cite) {
		say " - getting citation " if ($opt_debug);
		my $citation = getArtifactText($artifact->{id}.'/provenance/citations.bib', $opt_filename);

		$citation=~s/\n\n/\n/g;
		if ($opt_citation_file) {
			say STDERR "Saving citation to <$opt_cite>";
			open my $outfile, '>', "$opt_citation_file" || die "FATAL ERROR:\nUnable to write citation to <$opt_citation_file>.\n";
			print {$outfile} $citation;
		} else {
			say "$citation";
		}
	}

	if (defined $opt_data) {

	}
	if (defined $opt_info) {
		say GREEN, $artifact->{id}, RESET, BOLD, "\t", $opt_filename, RESET;
		if ($artifact->{type} eq 'Visualization') {
			say BLUE "<HTML document>", RESET;
		} else {
			for my $f ( @{ $artifact->{data}}) {
				say BLUE $f, RESET;
			}
		}	
		say Dumper $artifact if ($opt_debug);
	} 
	if (defined $opt_extract) {
		debug("Extracting artifact to $opt_outdir");

		if (0) {
			say STDERR " - Specify output dir (-o) to extract the following files:";
			foreach my $i ( @{$artifact->{data} } ) {
				say  $i;
			}
		} else {
			if (! -d "$opt_outdir") {
				run( qq(mkdir "$opt_outdir"), [ 'description' => "Creating output directory <$opt_outdir>"] );
			} 

			run(
				qq(unzip -j  -o "$opt_filename" '$artifact->{id}/data/*' -d "$opt_outdir"),
				{
					'description' => "Extracting 'data' from $opt_filename to $opt_outdir",
					'error'       => "Unable to extract data."
				}
			);

			#run(
			#	qq(mv "$opt_outdir/$artifact->{id}/data/"* "$opt_outdir"),
			#);
			foreach my $i ( @{$artifact->{data} } ) {
				#my $cmd = qq(unzip -o  "$opt_filename" '$artifact->{id}/$i" -d "$opt_outdir");
				#run($cmd);
				my $base = basename($i);
				if ($base =~/\.biom/) {
					my $out = $base;
					$out =~s/biom/tsv/;
					my $BiomConvert = qq(biom convert --to-tsv -i "$opt_outdir/$base" -o "$opt_outdir/$out");
					
					
					run($BiomConvert, 
					{
							'description' => "Converting BIOM to TSV ($base)",
							'error'       => "Unable to convert $opt_outdir/$base to TSV using 'biom' tool",
					}) if ($biom_found);
				}
			}
			

		}
		
	}



}

sub init {
	$opt_version && version();
	pod2usage({-exitval => 0, -verbose => 2}) if $opt_help;
    die usage() if (0);
    checkBin('UNZIP', 'unzip');

    # is biom in path?
    my $checkBiom = qq(command -v biom);
    my $opt;
    $opt->{no_die} = 1;
    my $Biom = run($checkBiom, $opt);
    if ($Biom->{status} > 0) {
    	$biom_found = 0;
    } else {
    	$biom_found = 1;
    }
}

sub version {
    # Display version if needed
    print "$this_program $VERSION ($AUTHOR)\n";
     exit 0;
}
 
sub usage {
    # Short usage string in case of errors
    print "$this_program -x artifact.qza\n";
    exit 0;
}

sub debug {
	say STDERR "~ $_[0]" if ($opt_debug);
}

sub getArtifactText {
	my ($file, $filename) = @_;

	die "getArtifactText(x, y): y missing\n" unless (defined $filename);
	
	my $cmd_opt;
	my $cmd = qq(unzip -p "$filename" "$file");

	my $output = run($cmd, $cmd_opt);
	return $output->{as_string};

}

sub getArtifact {
	my $filename = shift @_;
	my $options;
	my $artifact;
	$options->{'description'} = "Getting artifact content from $filename";
	$options->{'error'}       = "Unable to get artifact content from 'unzip'";

	my $artifact_raw = run(
		qq(unzip -t "$filename"),
		$options
	);
	my $artifact_id;
	my @data;
	my %parents;
	my %files;
	foreach my $line ( @{$artifact_raw->{'lines'}} ) {
		chomp($line);
		if ($line=~/testing:\s+(.+?)\s+OK/) {
			my ($id, $root, @path) = split /\//, $1;
			my $stripped_path = $root;
			$stripped_path.= '/' . join('/', @path) if ($path[0]);
			$files{$stripped_path} = $1;
			
			if (! defined $artifact_id) {
				$artifact_id = $id;
			} elsif ($artifact_id ne $id) {
				die "ARTIFACT PARSING ERROR:\nArtifact has multiple roots ($artifact_id but also $id).\n";
			}
			if ($root eq 'data') {
				
				push(@data, $stripped_path);
				

			} elsif ($root eq 'provenance') {
				if ($path[0] eq 'artifacts') {
					$parents{$path[1]}++;
				}
				
			}

		}
	}

	my $yaml = YAML::Tiny->read_string( getArtifactText("$artifact_id/metadata.yaml", $filename) );
	$artifact->{'format'}  = $yaml->[0]->{format};
	$artifact->{'type'}    = $yaml->[0]->{type};
	$artifact->{'id'}      = $artifact_id;
	$artifact->{'parents'} = \%parents;
	$artifact->{'files'}   = \%files;
	$artifact->{'data'}    = \@data;
	return $artifact;

}

#unzip -p relative-table-ASV.qza ffc46e8f-1ae4-4a4a-af5d-c2593d32aa52/data/feature-table.biom | file -
sub run {
	my ($command, $opt) = @_;
	return 0 unless $command;

	my $out = undef;
	my @output = `$command`;
	debug("cmd:". $command);

	if ($opt->{'description'}) {
		debug("(". $opt->{"description"} .')') 
	}  
	if ($? and ! $opt->{no_die}) {
		print STDERR "ERROR RUNNING EXTERNAL COMAND:\n";
		print STDERR "Command: '$command' (",$opt->{'description'},")\n";
		print STDERR $opt->{'error'}, "\n";
		exit $?;
	}
	my $string = join("\n", @output);
	$out->{status} = $?;
	$out->{as_string} = $string;
	$out->{lines} = \@output;


	return $out;
}

sub checkBin {
	my ($commandName, $commandString) = @_;
	my $opt_command;
    $opt_command->{'description'} = 'Checking presence of "'. $commandName .'"';
    $opt_command->{'error'}       = 'Please, ensure that "'.$commandName.'" is present in your path';
    run($commandString, $opt_command);
}
__END__
 
=head1 NAME
 
B<qzoom.pl> - a helper utility to extract data from Qiime2 artifact
 
=head1 AUTHOR
 
Andrea Telatin <andrea@telatin.com>
 
=head1 SYNOPSIS
 
qzoom.pl [options] <artifact_file.qza/v>
 
=head1 OPTIONS
 
=over 2

B<-c, --cite> [I<PATH>]

Print artifact citation to STDOUT or to file, is a filepath is provided

B<-x, --extract> [I<OUTDIR>]

Print the list of files in the 'data' directory. 
If a OUTDIR is provided, extract the content of the 'data' directory (i.e. the actual output of the artifact).
Will create the directory if not found. Will overwrite files in the directory.


 
=back
 
=head1 BUGS
 
Please report them to <andrea@telatin.com>
 
=head1 COPYRIGHT
 
Copyright (C) 2019 Andrea Telatin 
 
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
 
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
 
You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
 
=cut