use YAML;
use Data::Dumper;
my ($hashref, $arrayref, $string) = YAML::LoadFile($ARGV[0]);

print Dumper ($hashref, $arrayref, $string);
