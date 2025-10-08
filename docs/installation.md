# Installation

## Via CPAN

The easiest way to install Qiime2::Artifact is via CPAN:

```bash
cpan Qiime2::Artifact
```

or using `cpanm`:

```bash
cpanm Qiime2::Artifact
```

## Manual Installation

You can also install manually from the source:

```bash
perl Makefile.PL
make
make test
make install
```

## From GitHub

To install the latest development version:

```bash
git clone https://github.com/telatin/qiime2tools.git
cd qiime2tools
dzil install
```

## Requirements

### System Requirements

- **Perl**: Version 5.14 or later
- **UnZip**: Version 6.00 or compatible (must be available in PATH)

### Perl Module Dependencies

The following Perl modules are required:

- `Carp` (1.2+)
- `Cwd` (3.31+)
- `Term::ANSIColor` (3.00+)
- `YAML::PP` (0.38 - **Important**: Version 0.38 specifically, later versions may not be compatible)
- `Capture::Tiny` (0.48+)
- `File::Basename` (2.82+)
- `autodie` (2.10+)
- `Data::Dumper` (2.1+)
- `FindBin` (1.3+)

### Optional Dependencies

- `File::Which` - For improved binary detection
- `biom` tool - For automatic BIOM to TSV conversion with qzoom

## Verifying Installation

After installation, verify that the module is working:

```bash
perl -MQiime2::Artifact -e 'print "Qiime2::Artifact version: $Qiime2::Artifact::VERSION\n"'
```

To verify the command-line tool:

```bash
qzoom --version
```

## Troubleshooting

### UnZip Not Found

If you get an error about `unzip` not being found:

**Linux (Debian/Ubuntu):**
```bash
sudo apt-get install unzip
```

**macOS:**
```bash
brew install unzip
```

**Specifying Custom UnZip Path:**

If `unzip` is not in your PATH, you can specify its location:

```perl
my $artifact = Qiime2::Artifact->new({
    filename => 'artifact.qza',
    unzip => '/usr/local/bin/unzip'
});
```

### YAML::PP Version Issues

If you experience issues with YAML parsing, ensure you have the correct version:

```bash
cpanm YAML::PP@0.38
```
