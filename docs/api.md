# API Reference

## Qiime2::Artifact

### Constructor

#### `new(%args)`

Creates a new Qiime2::Artifact object.

**Parameters:**

- `filename` (String, required) - Path to the artifact file
- `unzip` (String, optional) - Path to unzip program
- `debug` (Boolean, optional) - Enable debug mode
- `verbose` (Boolean, optional) - Enable verbose mode

**Returns:** Qiime2::Artifact object

**Dies:** If file not found, unzip not available, or artifact is invalid

**Example:**

```perl
my $artifact = Qiime2::Artifact->new({
    filename => 'artifact.qza'
});
```

### Instance Methods

#### `get($key)`

Retrieves an artifact attribute.

**Parameters:**

- `$key` (String) - Attribute name

**Returns:** Value of the attribute (type depends on attribute)

**Dies:** If attribute doesn't exist

**Available Keys:**

| Key | Type | Description |
|-----|------|-------------|
| `id` | String | Artifact UUID |
| `filename` | String | Absolute path to artifact file |
| `data` | ArrayRef | List of data files in artifact |
| `visualization` | Boolean | 1 if visualization, 0 if data artifact |
| `version` | String | QIIME 2 framework version |
| `archive` | String | Archive format version |
| `parents` | HashRef | Parent artifacts and their metadata |
| `ancestry` | ArrayRef[ArrayRef] | Hierarchical ancestry structure |
| `parents_number` | Integer | Number of parent artifacts |
| `imported` | Boolean | 1 if imported, 0 if derived |
| `loaded` | Boolean | Always 1 for successfully loaded artifacts |

**Example:**

```perl
my $id = $artifact->get('id');
my $parents = $artifact->get('parents');
```

#### `extract_file($data_file, $target_path)`

Extracts a specific file from the artifact's data directory.

**Parameters:**

- `$data_file` (String) - Name of file in artifact's data directory
- `$target_path` (String) - Path where file should be extracted

**Returns:** 1 on success

**Dies:** On extraction failure or missing parameters

**Example:**

```perl
$artifact->extract_file('taxonomy.tsv', '/output/taxonomy.tsv');
```

#### `get_bib()`

Extracts bibliography from the artifact's provenance.

**Parameters:** None

**Returns:** String containing BibTeX bibliography, or undef if none found

**Example:**

```perl
my $bib = $artifact->get_bib();
if (defined $bib) {
    print $bib;
}
```

### Private Methods

!!! note
    These methods are internal and should not be called directly.

#### `_read_artifact($self)`

Parses the artifact structure and populates object attributes.

#### `_getArtifactText($self, $file)`

Extracts text content from a file within the artifact.

#### `_get_parent($self, $key)`

Retrieves parent artifact information.

#### `_getAncestry($self)`

Builds the ancestry hierarchy.

#### `_check_unzip($unzip_path)`

Verifies unzip binary availability.

#### `_run($command_list)`

Executes external commands and captures output.

#### `_YAMLLoad($string, $info)`

Parses YAML strings.

#### `_crash($self, $msg)`

Handles fatal errors with formatted output.

#### `_debug($self, $msg, $data)`

Outputs debug messages when debug mode enabled.

#### `_verbose($self, $msg)`

Outputs verbose messages when verbose mode enabled.

## Data Structures

### Parents Hash Structure

```perl
{
    'self' => {
        'type' => 'method',
        'inputs' => [ ... ],
        'parameters' => [ ... ]
    },
    'parent-uuid-1' => {
        'metadata' => { ... },
        'action' => { ... },
        'from' => [ 'grandparent-uuid-1', ... ]
    },
    ...
}
```

### Ancestry Array Structure

```perl
[
    [ 'self-uuid' ],              # Generation 0 (this artifact)
    [ 'parent-1', 'parent-2' ],   # Generation 1 (parents)
    [ 'grandparent-1' ],          # Generation 2 (grandparents)
    ...
]
```

## Constants

### VALID_PARAMETERS

Hash defining valid constructor parameters and their descriptions.

```perl
{
    'filename' => 'Path to the artifact',
    'unzip'    => 'Path to the unzip program',
    'debug'    => 'Enable debug mode',
    'verbose'  => 'Enable verbose mode'
}
```

## Error Handling

The module uses `Carp::confess` for all errors. Errors include stack traces when verbose or debug mode is enabled.

Common error scenarios:

- **File not found:** "Filename not found: {path}"
- **Invalid artifact:** "is not a ZIP file" or "is not a valid artifact"
- **Missing unzip:** "UnZip not found as <path>"
- **Invalid attribute:** "<key> is not an attribute of this Artifact"
- **YAML parse error:** "YAMLLoad failed on string"

## Version

Current version: 0.14.0

Check version:

```perl
print $Qiime2::Artifact::VERSION;
```
