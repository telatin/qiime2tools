use 5.012;
use YAML::PP;
my $file;
my $ypp = YAML::PP->new;

open(my $i, '<', $ARGV[0]) || die;
while (my $r = readline($i)) {
	$file .= $r;
}

$ypp->load_string($file);