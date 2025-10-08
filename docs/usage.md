# Usage

## Basic Usage

### Loading an Artifact

```perl
use Qiime2::Artifact;

my $artifact = Qiime2::Artifact->new({
    filename => 'data/feature-table.qza'
});
```

### Constructor Parameters

The `new()` constructor accepts the following parameters:

- `filename` (required): Path to the artifact file (.qza or .qzv)
- `unzip` (optional): Path to unzip program (default: searches PATH)
- `debug` (optional): Enable debug mode (default: 0)
- `verbose` (optional): Enable verbose mode (default: 0)

```perl
my $artifact = Qiime2::Artifact->new({
    filename => 'data/taxonomy.qzv',
    unzip    => '/usr/bin/unzip',
    debug    => 1,
    verbose  => 1
});
```

## Accessing Artifact Information

### Using the get() Method

The `get()` method retrieves artifact attributes:

```perl
# Get artifact UUID
my $id = $artifact->get('id');

# Check if it's a visualization
my $is_viz = $artifact->get('visualization');

# Get QIIME 2 version
my $version = $artifact->get('version');

# Get archive version
my $archive = $artifact->get('archive');

# Get data files list
my $data_files = $artifact->get('data');
foreach my $file (@$data_files) {
    print "Data file: $file\n";
}
```

### Available Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `id` | String | Artifact UUID |
| `data` | ArrayRef | List of data files in artifact |
| `visualization` | Boolean | True if artifact is a visualization |
| `version` | String | QIIME 2 version used to create artifact |
| `archive` | String | Archive format version |
| `parents` | HashRef | Parent artifacts information |
| `ancestry` | ArrayRef | Complete artifact lineage |
| `parents_number` | Integer | Number of parent artifacts |
| `imported` | Boolean | True if artifact was imported (not derived) |

## Extracting Files

### Extract a Data File

```perl
# Extract a specific file from the artifact
$artifact->extract_file('taxonomy.tsv', '/path/to/output/taxonomy.tsv');
```

This method:
- Extracts the specified file from the artifact's data directory
- Writes it to the target path
- Dies with an error message on failure

## Working with Provenance

### Getting Parent Information

```perl
my $parents = $artifact->get('parents');

foreach my $parent_id (keys %$parents) {
    next if $parent_id eq 'self';  # Skip the artifact itself

    my $parent = $parents->{$parent_id};
    my $action = $parent->{action};
    print "Parent ID: $parent_id\n";
    print "Action: $action->{type}\n";
}
```

### Tracing Ancestry

```perl
my $ancestry = $artifact->get('ancestry');

for (my $i = 0; $i < scalar @$ancestry; $i++) {
    print "Generation $i:\n";
    foreach my $ancestor_id (@{$ancestry->[$i]}) {
        print "  - $ancestor_id\n";
    }
}
```

## Extracting Citations

```perl
my $bibliography = $artifact->get_bib();

if (defined $bibliography) {
    print $bibliography;

    # Or save to file
    open my $fh, '>', 'citations.bib';
    print $fh $bibliography;
    close $fh;
} else {
    print "No bibliography found\n";
}
```

## Error Handling

The module uses `Carp::confess` for error handling and will die with detailed error messages:

```perl
use Try::Tiny;

my $artifact;
try {
    $artifact = Qiime2::Artifact->new({
        filename => 'nonexistent.qza'
    });
} catch {
    warn "Error loading artifact: $_";
};
```

Common errors:
- File not found
- Invalid artifact format
- Missing unzip program
- Corrupted ZIP file
- Invalid attribute access

## Working with Visualizations

```perl
my $viz = Qiime2::Artifact->new({
    filename => 'taxonomy.qzv'
});

if ($viz->get('visualization')) {
    print "This is a visualization artifact\n";

    # Check for index.html
    my @files = @{$viz->get('data')};
    if (grep { $_ eq 'index.html' } @files) {
        print "Contains web visualization\n";

        # Extract the visualization
        $viz->extract_file('index.html', 'taxonomy_viz.html');
    }
}
```
