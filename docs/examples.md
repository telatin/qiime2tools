# Examples

## Basic Examples

### Loading and Inspecting an Artifact

```perl
use Qiime2::Artifact;

my $artifact = Qiime2::Artifact->new({
    filename => 'feature-table.qza'
});

printf "Artifact ID: %s\n", $artifact->get('id');
printf "QIIME 2 version: %s\n", $artifact->get('version');
printf "Archive version: %s\n", $artifact->get('archive');
printf "Is visualization: %s\n", $artifact->get('visualization') ? 'Yes' : 'No';
printf "Number of parents: %d\n", $artifact->get('parents_number');
```

### Listing Data Files

```perl
use Qiime2::Artifact;

my $artifact = Qiime2::Artifact->new({
    filename => 'taxonomy.qza'
});

my $data_files = $artifact->get('data');

print "Data files in artifact:\n";
foreach my $file (@$data_files) {
    print "  - $file\n";
}
```

### Extracting Files

```perl
use Qiime2::Artifact;
use File::Spec;

my $artifact = Qiime2::Artifact->new({
    filename => 'feature-table.qza'
});

my $data_files = $artifact->get('data');

# Extract all data files
foreach my $file (@$data_files) {
    my $output_path = File::Spec->catfile('output', $file);
    print "Extracting $file to $output_path\n";
    $artifact->extract_file($file, $output_path);
}
```

## Provenance Analysis

### Examining Parent Artifacts

```perl
use Qiime2::Artifact;
use Data::Dumper;

my $artifact = Qiime2::Artifact->new({
    filename => 'filtered-table.qza'
});

my $parents = $artifact->get('parents');

print "Parent artifacts:\n";
foreach my $parent_id (keys %$parents) {
    next if $parent_id eq 'self';

    my $parent = $parents->{$parent_id};
    print "\nParent ID: $parent_id\n";

    if (defined $parent->{action}) {
        printf "  Action type: %s\n", $parent->{action}->{type};
        printf "  Plugin: %s\n", $parent->{action}->{plugin}
            if defined $parent->{action}->{plugin};
    }

    if (defined $parent->{from} && @{$parent->{from}}) {
        print "  Input from: ", join(', ', @{$parent->{from}}), "\n";
    }
}
```

### Tracing Complete Ancestry

```perl
use Qiime2::Artifact;

my $artifact = Qiime2::Artifact->new({
    filename => 'final-output.qza'
});

my $ancestry = $artifact->get('ancestry');

print "Artifact ancestry (generation by generation):\n\n";
for (my $i = 0; $i < scalar @$ancestry; $i++) {
    printf "Generation %d (%d artifact%s):\n",
        $i,
        scalar @{$ancestry->[$i]},
        scalar @{$ancestry->[$i]} == 1 ? '' : 's';

    foreach my $ancestor_id (@{$ancestry->[$i]}) {
        print "  - $ancestor_id\n";
    }
    print "\n";
}
```

## Working with Visualizations

### Detecting and Extracting Visualizations

```perl
use Qiime2::Artifact;

my $artifact = Qiime2::Artifact->new({
    filename => 'taxonomy.qzv'
});

if ($artifact->get('visualization')) {
    print "This is a visualization artifact\n";

    my $data_files = $artifact->get('data');

    # Check if it contains an HTML visualization
    if (grep { $_ eq 'index.html' } @$data_files) {
        print "Contains HTML visualization\n";

        # Extract the HTML file
        $artifact->extract_file('index.html', 'taxonomy_view.html');
        print "Extracted visualization to taxonomy_view.html\n";

        # You can now open it in a browser
        system('open', 'taxonomy_view.html') if $^O eq 'darwin';
    }
}
```

## Bibliography Management

### Extracting Citations

```perl
use Qiime2::Artifact;

my $artifact = Qiime2::Artifact->new({
    filename => 'taxonomy.qza'
});

my $bibliography = $artifact->get_bib();

if (defined $bibliography) {
    # Save to file
    open my $fh, '>', 'citations.bib' or die $!;
    print $fh $bibliography;
    close $fh;

    print "Bibliography saved to citations.bib\n";

    # Count citations
    my @entries = $bibliography =~ /\@\w+\{/g;
    printf "Found %d citation(s)\n", scalar @entries;
} else {
    print "No bibliography found in this artifact\n";
}
```

### Merging Citations from Multiple Artifacts

```perl
use Qiime2::Artifact;

my @artifact_files = qw(table.qza taxonomy.qza tree.qza);
my %unique_citations;

foreach my $file (@artifact_files) {
    my $artifact = Qiime2::Artifact->new({ filename => $file });
    my $bib = $artifact->get_bib();

    if (defined $bib) {
        # Extract individual BibTeX entries
        while ($bib =~ /(\@\w+\{[^@]+)/g) {
            my $entry = $1;
            # Use first line as key for uniqueness
            my ($key) = $entry =~ /\@\w+\{([^,]+)/;
            $unique_citations{$key} = $entry if defined $key;
        }
    }
}

# Save merged bibliography
open my $out, '>', 'all_citations.bib' or die $!;
foreach my $entry (values %unique_citations) {
    print $out $entry, "\n\n";
}
close $out;

printf "Merged %d unique citations\n", scalar keys %unique_citations;
```

## Batch Processing

### Processing Multiple Artifacts

```perl
use Qiime2::Artifact;
use File::Find;

my @artifacts;

# Find all .qza files in a directory
find(sub {
    push @artifacts, $File::Find::name if /\.qza$/;
}, 'qiime2_output');

print "Found ", scalar @artifacts, " artifacts\n\n";

foreach my $file (@artifacts) {
    eval {
        my $artifact = Qiime2::Artifact->new({ filename => $file });

        printf "File: %s\n", $file;
        printf "  ID: %s\n", $artifact->get('id');
        printf "  Version: %s\n", $artifact->get('version');
        printf "  Parents: %d\n", $artifact->get('parents_number');
        print "\n";
    };

    if ($@) {
        warn "Error processing $file: $@\n";
    }
}
```

### Creating a Summary Report

```perl
use Qiime2::Artifact;

sub analyze_artifact {
    my ($filename) = @_;

    my $artifact = Qiime2::Artifact->new({ filename => $filename });

    return {
        id => $artifact->get('id'),
        version => $artifact->get('version'),
        is_viz => $artifact->get('visualization'),
        imported => $artifact->get('imported'),
        parents => $artifact->get('parents_number'),
        data_files => scalar @{$artifact->get('data')}
    };
}

my @files = glob('*.qza');
my @report;

foreach my $file (@files) {
    eval {
        my $info = analyze_artifact($file);
        push @report, { filename => $file, %$info };
    };
}

# Print CSV report
print "Filename,ID,Version,Visualization,Imported,Parents,DataFiles\n";
foreach my $entry (@report) {
    printf "%s,%s,%s,%d,%d,%d,%d\n",
        $entry->{filename},
        $entry->{id},
        $entry->{version},
        $entry->{is_viz} ? 1 : 0,
        $entry->{imported} ? 1 : 0,
        $entry->{parents},
        $entry->{data_files};
}
```

## Advanced Usage

### Custom UnZip Path

```perl
use Qiime2::Artifact;

my $artifact = Qiime2::Artifact->new({
    filename => 'artifact.qza',
    unzip => '/usr/local/bin/unzip'
});
```

### Debug Mode

```perl
use Qiime2::Artifact;

my $artifact = Qiime2::Artifact->new({
    filename => 'artifact.qza',
    debug => 1,
    verbose => 1
});

# Will print detailed debug information
my $id = $artifact->get('id');
```

### Error Handling with Try::Tiny

```perl
use Qiime2::Artifact;
use Try::Tiny;

my $artifact;

try {
    $artifact = Qiime2::Artifact->new({
        filename => 'artifact.qza'
    });

    print "Successfully loaded artifact\n";
    print "ID: ", $artifact->get('id'), "\n";

} catch {
    my $error = $_;

    if ($error =~ /not found/) {
        print "File does not exist\n";
    } elsif ($error =~ /not a ZIP file/) {
        print "File is not a valid artifact\n";
    } else {
        print "Unknown error: $error\n";
    }
};
```

## Integration Examples

### With BioPerl

```perl
use Qiime2::Artifact;
use Bio::SeqIO;

# Extract sequences from QIIME 2 artifact
my $artifact = Qiime2::Artifact->new({
    filename => 'sequences.qza'
});

$artifact->extract_file('sequences.fasta', 'temp_sequences.fasta');

# Process with BioPerl
my $seqio = Bio::SeqIO->new(
    -file => 'temp_sequences.fasta',
    -format => 'fasta'
);

my $count = 0;
while (my $seq = $seqio->next_seq) {
    $count++;
    print "Sequence ", $count, ": ", $seq->id, "\n";
}

unlink 'temp_sequences.fasta';
```

### Generating HTML Reports

```perl
use Qiime2::Artifact;

my $artifact = Qiime2::Artifact->new({
    filename => 'artifact.qza'
});

my $html = sprintf qq{
<!DOCTYPE html>
<html>
<head><title>Artifact Report</title></head>
<body>
    <h1>QIIME 2 Artifact Report</h1>
    <table>
        <tr><th>ID</th><td>%s</td></tr>
        <tr><th>Version</th><td>%s</td></tr>
        <tr><th>Parents</th><td>%d</td></tr>
        <tr><th>Imported</th><td>%s</td></tr>
    </table>
</body>
</html>
},
    $artifact->get('id'),
    $artifact->get('version'),
    $artifact->get('parents_number'),
    $artifact->get('imported') ? 'Yes' : 'No';

open my $fh, '>', 'report.html';
print $fh $html;
close $fh;
```
