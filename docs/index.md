# Qiime2::Artifact

A Perl module for parsing and extracting information from QIIME 2 artifact files (`.qza` and `.qzv`).

[![Perl](https://img.shields.io/badge/perl-5.14+-brightgreen.svg)](https://dev.perl.org/)
[![CPAN version](https://img.shields.io/cpan/v/Qiime2-Artifact)](https://metacpan.org/pod/Qiime2::Artifact)

## Overview

Qiime2::Artifact provides a simple interface to work with QIIME 2 artifacts, allowing you to extract metadata, provenance information, and file contents from both `.qza` (data artifacts) and `.qzv` (visualization artifacts) files.

## Features

- Parse QIIME 2 artifact metadata
- Extract provenance information
- Track artifact ancestry
- Extract data files from artifacts
- Extract bibliographic citations
- Command-line tool (`qzoom`) for quick inspection

## Quick Start

```perl
use Qiime2::Artifact;

# Load a QIIME 2 artifact
my $artifact = Qiime2::Artifact->new({
    filename => 'data/feature-table.qza'
});

# Get basic information
my $id = $artifact->get('id');
my $version = $artifact->get('version');
print "Artifact ID: $id\n";
print "QIIME 2 version: $version\n";
```

## Quick Command-Line Usage

```bash
# View artifact information
qzoom --info artifact.qza

# Extract data files
qzoom --extract --outdir output/ artifact.qza

# Get citations
qzoom --cite artifact.qza
```

## Documentation

- [Installation](installation.md) - How to install the module
- [Usage](usage.md) - Basic usage examples
- [API Reference](api.md) - Complete API documentation
- [qzoom CLI](qzoom.md) - Command-line tool documentation
- [Examples](examples.md) - More detailed examples
- [Contributing](contributing.md) - How to contribute

## Requirements

- Perl 5.14 or later
- UnZip 6.00 or compatible
- YAML::PP (version 0.38)

## License

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

## Author

Andrea Telatin

## Links

- [GitHub Repository](https://github.com/telatin/qiime2tools)
- [CPAN](https://metacpan.org/pod/Qiime2::Artifact)
- [QIIME 2 Documentation](https://docs.qiime2.org/)
