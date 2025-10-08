# qzoom - Command-Line Tool

`qzoom` is a command-line utility for inspecting and extracting information from QIIME 2 artifacts.

## Installation

`qzoom` is installed automatically with the Qiime2::Artifact module and should be available in your PATH after installation.

## Usage

```bash
qzoom [OPTIONS] artifact.qza
```

## Options

### Information Display

#### `--info, -i`

Display artifact information including ID, version, type, and parent count.

```bash
qzoom --info artifact.qza
```

**Output example:**
```
Artifact ID: d27b6a68-5c6e-46d9-9866-7b4d46cca533
QIIME 2 version: 2023.5.0
Type: FeatureTable[Frequency]
Parents: 2
```

#### `--data, -d`

List data files contained in the artifact.

```bash
qzoom --data artifact.qza
```

**Output example:**
```
Data files in artifact:
  - feature-table.biom
  - metadata.yaml
```

### Citation Information

#### `--cite, -c`

Display bibliography information from the artifact.

```bash
qzoom --cite artifact.qza
```

This extracts and displays the BibTeX entries from the artifact's provenance.

#### `--bibtex FILE, -b FILE`

Save bibliography to a specified BibTeX file.

```bash
qzoom --bibtex citations.bib artifact.qza
```

### File Extraction

#### `--extract, -x`

Extract data files from the artifact.

```bash
qzoom --extract artifact.qza
```

By default, files are extracted to the current directory.

#### `--outdir DIR, -o DIR`

Specify output directory for extracted files.

```bash
qzoom --extract --outdir output/ artifact.qza
```

#### `--rename, -r`

Rename extracted files to include the artifact ID prefix.

```bash
qzoom --extract --rename artifact.qza
```

This creates files like `{artifact-id}_feature-table.biom`.

### General Options

#### `--verbose`

Enable verbose output showing detailed operations.

```bash
qzoom --verbose --info artifact.qza
```

#### `--force-ext, -f`

Force processing of files with non-standard extensions.

```bash
qzoom --force-ext --info artifact.zip
```

#### `--version, -v`

Display qzoom version.

```bash
qzoom --version
```

#### `--help, -h`

Display help information.

```bash
qzoom --help
```

## Examples

### Inspect an Artifact

```bash
qzoom --info feature-table.qza
```

### Extract All Data Files

```bash
qzoom --extract --outdir extracted/ feature-table.qza
```

### Get Citations and Save to File

```bash
qzoom --bibtex references.bib taxonomy.qza
```

### Extract and Rename Files

```bash
qzoom --extract --rename --outdir results/ artifact.qza
```

### Verbose Extraction

```bash
qzoom --verbose --extract --outdir output/ artifact.qza
```

## BIOM Conversion

If the `biom` tool is available in your PATH, `qzoom` will automatically convert BIOM files to TSV format during extraction.

```bash
# Extracts feature-table.biom and automatically creates feature-table.tsv
qzoom --extract artifact.qza
```

To install the biom tool:

```bash
pip install biom-format
```

## Working with Visualizations

Visualizations (.qzv files) can be processed the same way as data artifacts:

```bash
# Extract visualization files including index.html
qzoom --extract taxonomy.qzv

# View info
qzoom --info taxonomy.qzv
```

## Exit Codes

- `0` - Success
- `1` - Error (file not found, invalid artifact, etc.)

## Tips

1. **Batch Processing:** Use shell loops to process multiple artifacts:

```bash
for file in *.qza; do
    echo "Processing $file"
    qzoom --info "$file"
done
```

2. **Quick Inspection:** Combine options to get comprehensive information:

```bash
qzoom --info --data --cite artifact.qza
```

3. **Organized Extraction:** Create separate directories for each artifact:

```bash
artifact="feature-table.qza"
id=$(qzoom --info "$artifact" | grep "Artifact ID" | cut -d' ' -f3)
qzoom --extract --outdir "extracted/$id" "$artifact"
```

## Integration with Pipelines

`qzoom` can be integrated into bioinformatics pipelines:

```bash
#!/bin/bash
# Extract and process QIIME 2 artifacts

INPUT_DIR="qiime2_results"
OUTPUT_DIR="extracted_data"

for artifact in $INPUT_DIR/*.qza; do
    basename=$(basename "$artifact" .qza)
    qzoom --extract --outdir "$OUTPUT_DIR/$basename" "$artifact"
done
```

## See Also

- [Usage Guide](usage.md) - Perl API usage
- [Examples](examples.md) - More examples
- [API Reference](api.md) - Complete API documentation
