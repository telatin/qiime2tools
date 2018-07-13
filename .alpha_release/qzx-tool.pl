#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;
use Getopt::Long;
use YAML::XS 'Load';
use Data::Dumper;
use Term::ANSIColor  qw(:constants);


# Input parameters
my ($opt_debug, $opt_nocolor);

my $opt_get = GetOptions(
	'nocolor'      =>    \$opt_nocolor,
	'd|debug'      =>    \$opt_debug
);

# 'qza' file
my $opt_filename = shift(@ARGV);


if (!defined($opt_filename)) {
	crash("Missing parameter: input file.", 1)
} elsif (!-e "$opt_filename") {
	crash("Unable to find input file: \"$opt_filename\".", 2)
}
info("Input file", $opt_filename);

my ($UUID, @archive_files_list) = scan_files($opt_filename);
my %VERSION = parse_version(get_text_file('VERSION'));


info('Version', $VERSION{'version'} . ' (framework=' . $VERSION{'framework'} . ')');

my $metadata = get_data_from_yaml('metadata.yaml');
my $action   = get_data_from_yaml('provenance/action/action.yaml');
my $ACTION_UUID = $action->{execution}->{uuid};
#print Dumper $metadata;

title('File Metadata');
info('UUID',    "$UUID");
info('Type',    $metadata->{type});
info('Format',  $metadata->{format});
print STDERR "\n";

title('File Action');
info('UUID',    $ACTION_UUID);
info('Action',  $action->{action}->{action});
print STDERR "\n";

#my $provenance = get_data_from_yaml('provenance/action/action.yaml');
#print Dumper $provenance;

#"005" [shape=box     , regular=1,style=filled,fillcolor=white   ] ;


#"action2" [shape=point,label="38589482-ca8b-4202-9ff1-438305aef15e",style=filled,height=.1,width=.1] ;
 
#"001" -> "action1" [dir=none,weight=1] ;

open(PLOT, ">$opt_filename.dot");
print PLOT qq(digraph Ped_Lion_Share           {
	rankdir=LR;
	label = "$opt_filename Provenance" ;
	node [color=grey, style=filled]; );

my $DATA;
foreach my $file (@archive_files_list) {
	if ($file=~/^provenance\/artifacts\/([a-f0-9-]+)\/.*(action|metadata)\.yaml$/) {
		my $yaml = get_data_from_yaml($file);
		info("$2$1>", $file);	
		$DATA->{"$1"}->{"$2"} = $yaml;

		if ($2 eq 'metadata') {
			plot_file($yaml->{uuid})
		} else {
			#plot_action($yaml->{execution}->{uuid});

			my @inputs = $yaml->{action}->{inputs};
			foreach my $i (@inputs) {

				next unless (defined $i);			
				my @array = @{$i};
				foreach my $pair (@array) {
					foreach my $key (keys %{$pair}) {
						info($key, ${$pair}{$key});
						plot_arrow($1, ${$pair}{$key})
					}
				}
			}
		}
	}
	
	#print get_text_file($file);
} 
sub plot_action {
 
	my $id = shift(@_);
	print PLOT qq("$id" [shape=point,label="$id",style=filled,height=.1,width=.1] ;\n);
}
sub plot_file {
	my $id = shift(@_);
	print PLOT qq("$id" [style=filled,fillcolor=white   ] ;\n);
}
sub plot_arrow {
	my ($from, $to) = @_;
	print PLOT qq("$from" -> "$to" [weight=1]; \n );
}

my $finish = 0;
my $id = $UUID;
plot_file($UUID);
my $this_action = $action;
while ($finish < 1) {
	my @inputs = $this_action->{action}->{inputs};
	#print Dumper @inputs;

	foreach my $i (@inputs) {
		info('----','----');
		my @array;
		if (defined $i) {
			@array = @{$i};
		} else {
			@array = ()
		}

		foreach my $pair (@array) {
			foreach my $key (keys %{$pair}) {
				info($key, ${$pair}{$key});
				plot_arrow($UUID, ${$pair}{$key})
			}
		}
	}
	#print Dumper $DATA->{'51e2bb0c-cd30-48d9-8ac6-e26a8f3744c0'}->{action};
	last;
}



print PLOT "\n}\n";
exc(qq(dot -Tpng "$opt_filename.dot" > "$opt_filename.png"));
#----------------
sub get_data_from_yaml {
	my $file = shift(@_);
	my $yaml_text = get_text_file($file);
	my $yaml = Load $yaml_text;
	return $yaml;
}
sub parse_version {
	my $raw_version = shift(@_);
	my %output;
	my @lines = split /\n/, $raw_version;
	my $version = @lines[0];
	$output{'version'} = $lines[0];
	if ($lines[1]=~/archive:\s+(\d+)/) {
		$output{'archive'} = $1;
	}
	if ($lines[2]=~/framework:\s+(.+)/) {
		$output{'framework'} = $1;
	}

	return %output;
}
sub get_text_file {
	my $filename = shift(@_);
	my $text = exc(qq(unzip -p "$opt_filename" "$UUID/$filename"));
	return $text;
}
sub scan_files {
	my $filename = shift(@_);
	my $raw_output = exc(qq(unzip -t "$filename"));
	my @raw_lines = split /\n/, $raw_output;
	my @output_paths;
	my $prev;
	foreach my $line (@raw_lines) {
		if ($line=~/testing:\s+([^\/]+)\/(.*?)\s+OK/) {
			my $id = $1;
			warning("SCANNING FILES: UUID=$id differs from previous ($prev)") if (defined $prev and $prev ne $id);
			$prev = $id;
			push(@output_paths, $2);
		}
	}
	return ($prev, @output_paths);
}
sub crash {
	my ($message, $error_code) = @_;
	print STDERR " FATAL ERROR:\n";
	print STDERR " $message\n";
	exit $error_code;
}

sub info {
	my ($key, $value) = @_;
	$key = '<key>' unless defined $key;
	$value='<>' unless defined $value;
	my $col_size = 20;
	print STDERR GREEN if (!$opt_nocolor);
	$key = substr($key, 0, ($col_size-3)) . '...' if (length($key)>=$col_size);
	my $space = ' ' x ($col_size-length($key));
	print STDERR " $key$space", RESET, "$value\n", RESET;
}
sub title {
	my $title=shift(@_);
	print STDERR  BOLD if (!$opt_nocolor);
	my $width = 30;
	my $space = ' ' x ( ($width-length($title)) / 2 );
	print STDERR "\n$space=== $title ===$space\n";
	print STDERR RESET;
}
sub exc {
	my ($command) = @_;

	my $output = `$command`;

	if ($?) {
		crash("A command failed returning $?. Command:\n$command\n", $?);
	}
	return $output if (defined $output);
 
}
