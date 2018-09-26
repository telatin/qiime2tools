#!/usr/bin/env perl

# A program to export a Qiime2 visualization (qzv) to the public HTML folder
# of a GVL (Genomics Virtual Laboratory)

use v5.18;


use Term::ANSIColor  qw(:constants);
use Getopt::Long;
use Time::HiRes;
use File::Basename;
use Cwd;

my $opt_destination_folder = './';
my (
	$opt_verbose,
	$opt_basename,
);

say STDERR " QIIME2 ARTIFACT EXTRACTOR

Usage:
extract_data_from_artifact.pl [options] artifact_file1 artifact_file2 ...

  -d DIR              Destination directory where to expand artifacts
  -b                  Use artifact filename as subdirectory name instead of UUID

";
my $GetOptions = GetOptions(
	'v|verbose'	             => \$opt_verbose,
	'd|destination-folder=s' => \$opt_destination_folder,
	'b|basename'             => \$opt_basename,
);

my $check_version = run("qiime --version 2>/dev/null", "Checking Qiime2 version");
($check_version) = $check_version =~/version ([\.\w]+)/;
print STDERR YELLOW "Checking QIIME2 version: ", RESET, " $check_version\n", RESET;


if (defined $opt_destination_folder and ! -d $opt_destination_folder) {
	run( qq(mkdir -p "$opt_destination_folder"), "Creating destination folder: $opt_destination_folder");
}

foreach my $artifact_file (@ARGV) {
	print STDERR GREEN "Processing ", BOLD, $artifact_file, RESET, "\n";
	#my $id = run(qq(unzip  -t "$input_file" |  grep testing | cut -f 2 -d : | cut -f1 -d/ |sort -u));
	my $destination_folder;
	
	my ($uuid, $type, $format) = getArtifactPeek($artifact_file);
	
	if (defined $opt_basename) {
		$destination_folder = $opt_destination_folder . '/' . basename($artifact_file);
	} else {
		$destination_folder = $opt_destination_folder . '/' .$uuid;
	}

	if (! -d "$destination_folder") {
		run( qq(mkdir "$destination_folder"),
			 "Creating destination directory: $destination_folder"
			);

	}

	print STDERR YELLOW "UUID\t", RESET, "$uuid\n";
	print STDERR YELLOW "Type\t", RESET, "$type\n";
	print STDERR YELLOW "Dest\t", RESET, "$destination_folder\n";
	
	my $random = int( 99_999_999 * rand() );
	run("mkdir /tmp/$random/", "Creating temporary directory");
	run( qq(unzip  "$artifact_file" -d "/tmp/$random/"),
		"Extracting $artifact_file into temporary directory");

	run ( qq(mv /tmp/$random/$uuid/data/* $destination_folder),
		"Moving $artifact_file data content to $destination_folder"
		); 

	run ( qq(rm -rf "/tmp/$random/") ,
		"Removing temporary directory /tmp/$random/")
}


sub getArtifactPeek {
	my $file = shift @_;
	my $rawoutput = run(qq(qiime tools peek "$file"));
	my @output = split /\n/, $rawoutput;
	my ($uuid, $type, $format);
	die "Not enough output lines from peek $#output:\n @output" if (!$output[1]);
	foreach my $line (@output) {
		say STDERR "---> $line\n" if ($opt_verbose);
		chomp($line);
		my ($k, $value) = split /:\s+/, $line;
		if ($k eq 'UUID') {
			$uuid = $value;
		} elsif ($k eq 'Type') {
			$type = $value;
		} elsif ($k eq 'Data format') {
			$format = $value;
		} else {
			say STDERR "Unrecognized qiime peek line: [$k, $value]\n$line\n";
		}
	}

	die " FATAL ERROR:\n Getting peek from '$file' returned unrecognized output:\n @output\n\nUnable to detect UUID\n"
		if (!$type or !$uuid);

	return ($uuid, $type, $format);
}

sub run {
	my ($cmd, $action) = @_;
	my $output = `$cmd`;

	if ($?) {
		print STDERR RED " FATAL ERROR:\n", RESET, " Execution of a command failed (exit: $?). Command:\n", GREEN, " $cmd\n", RESET, "\n Action: ", BOLD, "\n $action", RESET, "\n";
		exit 10
	}
	return $output;
}
