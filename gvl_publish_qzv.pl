#!/usr/bin/env perl

# A program to export a Qiime2 visualization (qzv) to the public HTML folder
# of a GVL (Genomics Virtual Laboratory)

use v5.18;


use Term::ANSIColor  qw(:constants);
use Getopt::Long;
use Time::HiRes;
use File::Basename;
use Cwd;

our $artifacts_dir = 'qiime2';
our $this_script = $0;
our $this_script_config = $ENV{"HOME"} . "/.qiime2_visualizer_rc";
our $public_html_base_path = '/home/researcher/public_html/';
our $opt_dest_dir = $public_html_base_path. "/$artifacts_dir/";
our $this_ip = machine_ip();
our $uri_base = 'http://' . $this_ip . '/public/researcher/' . $artifacts_dir;
my $start_time = [Time::HiRes::gettimeofday()];
my $today_timestamp = run('date +"%Y-%m-%d (%H:%M)"');
chomp($today_timestamp);

my (
	$opt_folder_name,
	$opt_force_overwrite,
	$opt_verbose,
	$opt_rename,
	$opt_reinstall,
);

my $GetOptions = GetOptions(
		'v|verbose'				        => \$opt_verbose,
		'f|folder=s'                    => \$opt_folder_name,
		'r|rename'                      => \$opt_rename,
		'force'                         => \$opt_force_overwrite,
		'reinstall'                     => \$opt_reinstall,
);

splash_screen() unless ($ARGV[0]);

if ( (!-e $this_script_config) or $opt_reinstall ) {
	init();
}

if ($ARGV[0] and $> == 0) {
	print STDERR " RUNNING AS ROOT NOT ALLOWED\n", RESET;
	die " Running with 'sudo' required only to install this script. Run without sudo.\n";
}

$this_ip = '{YOUR_IP}' unless ($this_ip=~/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/);
print STDERR CYAN "Your IP:\t", RESET, $this_ip, "\n" if ($opt_verbose);

if (!-d "$opt_dest_dir") {
	die("Please create the output directory first ($opt_dest_dir missing)");
}

our $opt_unzip_dir = $opt_dest_dir;
if ($opt_folder_name) {
	$opt_folder_name.='/';
	run(qq(mkdir "$opt_dest_dir/$opt_folder_name/"));
	$opt_unzip_dir = "$opt_dest_dir/$opt_folder_name";
}

foreach my $input_file (@ARGV) {
		my $input_basename = basename($input_file);
		print STDERR BOLD "- $input_basename\n", RESET;

		# {id} get Qiime2 artifacts identifier
		# -------------------------------------------------------------------------------------------------------
		my $id = run(qq(unzip  -t "$input_file" |  grep testing | cut -f 2 -d : | cut -f1 -d/ |sort -u));
		chomp($id);                # Remove trailing newline
		die "FATAL ERROR:\nUnexpected artifact: should contain only a subdirectory\n:$id\n" if ($id=~/\n/);
		$id =~s/ //g;              # Strip spaces


		my $nickname = $input_basename;
		$nickname=~s/[^A-Za-z0-9_\.-]//g;
	

 
		print STDERR CYAN, "Identifier:\t", RESET, $id, "\n" if ($opt_verbose);

		my $out = run("unzip -o -d \"$opt_unzip_dir\" \"$input_file\" >/dev/null 2>&1");
		run(qq(echo "$nickname" > "$opt_unzip_dir/$id/data/name.txt"));		
#		if ($opt_rename) {
#			if (-d "$opt_dest_dir/$input_basename" and !$opt_force_overwrite) {
#				die " FATAL ERROR:\nArtifact id $id should be placed in '$input_basename'\nbut '$opt_dest_dir/$input_basename' is present and -f not specified.\n";
#			}	
#			run(qq(rm -rf "$opt_dest_dir/$input_basename")) if (-d "$opt_dest_dir/$input_basename");
#			run(qq(mv --force "$opt_dest_dir/$id" "$opt_dest_dir/$input_basename"));
#			$out=$input_basename;
#		}
		print STDERR CYAN "Artifact URL:\t", RESET, "$uri_base/$opt_folder_name$id/data\n";
		
		my $full_path = Cwd::abs_path($input_file);


		
}

create_index();


sub create_index {
	my $index_file = "$opt_dest_dir/index.html";
	open O, '>', "$index_file" || die " FATAL ERROR:\n Unable to write to index file\n";

	print O "<html>
	 <head>
	 	<style><!--
	 	body { font-family: Helvetica, Verdana; }
	 	h1 { color: navy; }
	 	h2 { color: #ccc; }
	 	a:link { color: navy; }
	 	a:visited { color: lightblue; }
	 	a:active  { color: red; }
	 	--></style>
	 </head>
	 <body>
	 <h1>Qiime2 Artifacts</h1>

	<ul>
	";
	my @output = `find "$opt_dest_dir" -name "data"`;

	foreach my $path (@output) {
		chomp($path);
		my $name = run( qq(cat "$path/name.txt") );
		$path =~s/$opt_dest_dir//;
		my ($subfolder) = split /\//, $path;
		print O "<li><a href=\"$path\">$name</a> <pre>$path</pre>
		</li>";
	}

	print O "</ul></body></html>\n";
    close O;	

}

sub machine_ip {
	my $this_ip = run( 'grep -v "127.0.0.1" /etc/hosts | grep $(hostname) | cut -f 1  -d " " ' );
	chomp($this_ip);
	$this_ip =~s/\s//g;
	if ($this_ip =~/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/) {
		return $this_ip;
	} else {
		return '{YOUR_VM_IP_HERE}';
	}

}
sub init {
	print STDERR GREEN "Initialization\n", RESET if ($opt_verbose);
	if ($> != 0) {
		print STDERR BOLD RED, "FATAL ERROR: 'sudo' required\n", RESET;
		die "Please, the first time you run this script please prepend 'sudo' \nto allow for initialization of the output directory\n";
	}

	if (! -d "$public_html_base_path") {
		print STDERR BOLD RED, "FATAL ERROR: IMPOSSIBLE TO INSTALL\n", RESET;
		die "This script is made for Genomic Virtual Laboratory images.\nPublic HTML directory ($public_html_base_path) was not found in this machine\n\n";
	}

	run("mkdir -p $opt_dest_dir");
	run("chown -R ubuntu:ubuntu $opt_dest_dir");
	run(qq(echo "IP:$this_ip" > $this_script_config ) );

	if (-e "$this_script_config") {
		print STDERR "Initialization finished. Created $this_script_config.\n" if ($opt_verbose);
	} else {
		die "FATAL ERROR:\nUnable to write to <$this_script_config>\n";
	}

	# open my $index_page, '>>', "$opt_dest_dir/index.html" || die " Unable to write HTML index: $opt_dest_dir/index.html\n";	
	# print {$index_page} "<html>
	# <head>
	# 	<style><!--
	# 	body { font-family: Helvetica, Verdana; }
	# 	h1 { color: navy; }
	# 	h2 { color: #ccc; }
	# 	a:link { color: navy; }
	# 	a:visited { color: lightblue; }
	# 	a:active  { color: red; }
	# 	--></style>
	# </head>
	# <body>
	# ";
	# close $index_page;
	#run("chown ubuntu:ubuntu $opt_dest_dir/index.html");

	if ($ARGV[0]) {
		print RED STDERR " WARNING!\n";
		print RESET STDERR " Initialization finished. Please, now run the command without sudo to export your files @ARGV\n";
	}
	exit;
}

sub run {
	my ($cmd) = @_;
	my $output = `$cmd`;
	die "FATAL ERROR:\nExecution of a shell command failed (exit status: $?). Command was:\n$cmd\n" if ($?);
	return $output;
}

sub splash_screen {
	print BOLD CYAN "
	-------------------------------------------------------
	Qiime 2.0 Visualization Exporter
	-------------------------------------------------------\n", RESET;
print <<END;
	Usage:
	$this_script [options] FILE.qzv ...

	OPTIONS:
	-f, --folder
			Name of the subfolder to extract the artifact to

	-v, --verbose
			Enable verbose output




	INSTALLATION:
	The first time run:
		sudo $this_script

	To reinstall:
		sudo $this_script --reinstall


END
}



