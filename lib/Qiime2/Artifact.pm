package Qiime2::Artifact;
#ABSTRACT: A parser for Qiime2 artifact files

use 5.016;
use warnings;
use autodie;
use Carp qw(confess);
use Cwd qw();
use Term::ANSIColor qw(:constants);
use Data::Dumper;
use YAML::PP;
use Capture::Tiny ':all';
use File::Basename;

$Qiime2::Artifact::VERSION = '1.00';

sub crash($);

sub new {
    # Instantiate object
    my ($class, $args) = @_;

    my $abs_path = Cwd::abs_path($args->{filename});
   	my $unzip_path = $args->{unzip} // 'unzip';

   	# Check supplied filename (abs_path uses the filesystem and return undef if file not found)
    crash "Filename not found: $args->{filename}" unless defined $abs_path;
    # Check unzip
    crash "UnZip not found as <$unzip_path>.\n" unless _check_output($unzip_path, 'UnZip 6.00');

    my $self = {

        filename_arg  => $args->{filename},


        debug         => $args->{debug} // 0,
        verbose       => $args->{verbose} // 0,
        filename      => $abs_path,
        unzip_path    => $unzip_path,
    };

    my $object = bless $self, $class;

    _read_artifact($object);


    return $object;
}

sub id {
	my ($self) = @_;
  if (defined $self->{id}) {
	   return $self->{id};
  } else {
    return 0;
  }
}

sub _read_artifact {
	my ($self) = @_;

  # Initialize attributes
  $self->{visualization} = 0  ;

	if (not defined $self->{filename}) {
		crash "_read_artifact: filename not defined $self";
	}

  my $artifact_raw = _run( qq(unzip -t "$self->{filename}" ));

  if ($artifact_raw->{status} != 0) {
    # Unzip -t failed: not a zip file
    crash("$self->{filename} is not a ZIP file");
  }
  my $artifact_id;
	my @artifact_data;
	my %artifact_parents;
	my %artifact_files;

  for my $line ( @{$artifact_raw->{'lines'}} ) {
    chomp($line);
    if ($line=~/testing:\s+(.+?)\s+OK/) {
      my ($id, $root, @path) = split /\//, $1;

      crash "$self->{filename} is not a valid artifact:\n  \"{id}/directory/data\" structure expected, found:\n  \"$1\"" unless (defined $path[0]);
      my $stripped_path = $root;
      $stripped_path.= '/' . join('/', @path) if ($path[0]);
      $artifact_files{$stripped_path} = $1;

      if (! defined $artifact_id) {
        $artifact_id = $id;
      } elsif ($artifact_id ne $id) {
        crash "Artifact format error: Artifact $self->{filename} has multiple roots ($artifact_id but also $id).\n";
      }
      if ($root eq 'data') {
        if (basename($stripped_path) eq 'index.html') {
          $self->{visualization} = 1;
        }
        push(@artifact_data, basename($stripped_path));


      } elsif ($root eq 'provenance') {
        if ($path[0] eq 'artifacts') {
          $artifact_parents{$path[1]}++;
        }

      }

    }
  }

  $self->{data} = \@artifact_data;

  if (not defined $self->{data}[0]) {
    crash("No data found in artifact $self->{filename}");
  }
  $self->{id} = $artifact_id;
  my $auto = YAMLLoad( $self->getArtifactText($self->{id} .'/provenance/action/action.yaml') , $self->{id} .'/provenance/action/action.yaml' );
  $self->{parents}->{self} = $auto->{action};

  for my $key (keys %artifact_parents) {
    # key=fa0cb712-1940-4971-9e7c-a08581e948ed
    my $parent = $self->get_parent($key);
    $self->{parents}->{$key} = $parent;
  }

  # Trace ancestry
  @{ $self->{ancestry} } = ();
  $self->{ancestry}[0] = [ $self->{id} ];


  for my $input (@{$self->{parents}->{self}->{inputs}}) {
      for my $key (sort keys %{ $input }) {

        push @{ $self->{ancestry}[1] }, $$input{ $key };
      }
  }


  while ($self->tree) {
    $self->{ancestry_levels}++;
  }

  $self->{loaded} = 1;
}

sub tree {
  my $self = $_[0];
  my $last_array = $self->{ancestry}[-1];
  return 0 unless ( ${ $last_array}[0] );

  foreach my $item (@{$self->{ancestry}[-1]}) {
    if (defined $self->{parents}->{$item}->{from}) {
      push @{$self->{ancestry}}, $self->{parents}->{$item}->{from};
      return 1;
    } else {
      return 0;
    }
  }
  return 0;
}
sub _check_output {
  # check if a command has a string in the output
  my ($cmd, $pattern) = @_;
  my $output = _run($cmd);
  if ($output->{stdout} =~/$pattern/) {
    return 1;
  } elsif ($output->{stderr} =~/$pattern/) {
    return 2;
  } else {
    return 0;
  }
}

sub get_parent {
  my ($self, $key) = @_;
  my $parent;

  my $metadata;
  my $action;
  # metadata= [id]/provenance/artifacts/[key]/metadata.yaml
  my $metadata_file = $self->{id} . "/provenance/artifacts/" . $key . '/metadata.yaml';
  $metadata = YAMLLoad( $self->getArtifactText($metadata_file), $metadata_file );

  # action = [id]/provenance/artifacts/[key]/action/action.yaml
  my $action_file = $self->{id} . "/provenance/artifacts/" . $key . '/action/action.yaml';
  $action = YAMLLoad( $self->getArtifactText($action_file), $action_file );

  $parent->{metadata} = $metadata;

  $parent->{action} = $action->{action};
  #for my $key (keys %{$action}) {
  #  $parent->{$key}   = $action->{$key};
  #}

  for my $input (@{$action->{action}->{inputs}}) {
      for my $key (sort keys %{ $input }) {
        push @{ $parent->{from} }, $$input{ $key };
      }
  }

  return $parent;
}

sub getArtifactText {
  my ($self, $file) = @_;
  my $command = qq(unzip -p "$self->{filename}" "$file" );
  my $out = _run($command);


  return $out->{stdout};
}
sub _run {
  my ($command, $opt) = @_;
  return 0 unless defined $command;

  # Perpare output data
  my $out = undef;

  my ($STDOUT, $STDERR, $OK) = capture {
    system($command);
  };

  $out->{cmd} = $command;
  $out->{status} = $OK;
  $out->{stdout} = $STDOUT;
  $out->{stderr} = $STDERR;
  my @output = split /\n/, $STDOUT;
  $out->{lines} = \@output;

  return $out;
}

sub YAMLLoad {
  my ($string, $info) = @_;
  my $ypp = YAML::PP->new;

  unless (length($string)) {
    crash "YAML string empty: unexpected error";
  }

  my $result = eval {
    $ypp->load_string($string);
  };

  if ($@) {
    crash "YAMLLoad failed on string $info:\n------------------------------------------------\n$string";
  } else {
    return $result;
  }
}

sub crash($) {
  chomp($_[0]);
	print STDERR BOLD RED " [Qiime2::Reader ERROR]",RESET,"\n";
	print STDERR RED " $_[0]\n ", '-' x 60, "\n", RESET;
	confess();
}

1;

__END__

=head1 Synopsis

  use Qiime2::Artifact;

  my $artifact = Qiime2::Artifact->new( {
        filename => 'tree.qza'
    } );

  print "Artifact_ID: ",  $artifact->{id};

=head1 Methods


=over 4


=item B<new()>

Load artifact from file. Parameters are: I<filename> (required).

=back


=head1 Artifact object

=over 4


=item B<id> I<(string)>

Artifact ID (example: C<cfdc04fb-9c26-40c1-a03b-88f79e5735f1>)

=item B<filename> I<(string)>

Full path of the input artifact.

=item B<visualizazion> I<(bool)>

Whether the artifact looks like a visualization artifact.
True (1) if the data contains C<index.html>.


=item B<data> I<(array)>

list of the files included in the 'data' directory

=item B<ancestry> I<(array of array)>

A list of levels of ancestry, each containing a list of Artifact IDs.
The first element is a list with the Artifact self ID. The last should contain the source artifact.
See also B<parents>.
Example:

  "ancestry" : [
      [
         "cfdc04fb-9c26-40c1-a03b-88f79e5735f1"
      ],
      [
         "96a220d6-107a-43c8-8d81-93ac4d111e3e",
         "3575de92-f7e7-4808-b0fa-b1a621ab984e"
      ],
      [
         "39771507-f226-4e18-aa30-cde40c3ea247"
      ]
   ],

=item B<parents> I<Hash>

Hash with all the provenance artifacts. Each parent has as key an Artifact ID, having as attributes:

=over 4

=item B<from>

List of artifact IDs originating the parent.

=item B<metadata>

Hash with C<key>, C<format>, C<uuid>.

=item B<action>

Structure containing C<citations>, C<parameters>, C<inputs> and other attributes.

=back

=back
