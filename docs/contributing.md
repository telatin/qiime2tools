# Contributing

Thank you for your interest in contributing to Qiime2::Artifact!

## Ways to Contribute

- Report bugs
- Suggest new features
- Improve documentation
- Submit code patches
- Write tests

## Getting Started

### 1. Fork and Clone

```bash
git clone https://github.com/telatin/qiime2tools.git
cd qiime2tools
```

### 2. Install Dependencies

Using Dist::Zilla:

```bash
cpanm Dist::Zilla
dzil authordeps --missing | cpanm
dzil listdeps --missing | cpanm
```

Or manually install requirements listed in `dist.ini`.

### 3. Run Tests

Before making changes, ensure all tests pass:

```bash
prove -l t/
```

Or using Dist::Zilla:

```bash
dzil test
```

## Development Workflow

### 1. Create a Branch

```bash
git checkout -b feature/my-new-feature
```

or

```bash
git checkout -b fix/bug-description
```

### 2. Make Your Changes

Follow the code style guidelines in [CLAUDE.md](https://github.com/telatin/qiime2tools/blob/master/CLAUDE.md).

Key points:
- Use `strict` and `warnings`
- Minimum Perl version: 5.014
- Private methods prefixed with underscore
- Use `Carp::confess` for errors
- Add POD documentation
- Use spaces for indentation (not tabs)

### 3. Add Tests

Add tests in the `t/` directory:

```perl
use strict;
use warnings;
use Test::More;
use Qiime2::Artifact;

# Your test code here

done_testing;
```

### 4. Run Tests

```bash
prove -lv t/
```

### 5. Update Documentation

- Update POD in the module if API changes
- Update README.md if needed
- Update docs/ for ReadTheDocs

### 6. Commit Changes

```bash
git add .
git commit -m "Brief description of changes"
```

Follow conventional commit messages:
- `feat:` for new features
- `fix:` for bug fixes
- `docs:` for documentation changes
- `test:` for test additions/changes
- `refactor:` for code refactoring

### 7. Push and Create Pull Request

```bash
git push origin feature/my-new-feature
```

Then create a pull request on GitHub.

## Testing

### Running All Tests

```bash
prove -l t/
```

### Running a Single Test

```bash
prove -lv t/12_basic_attributes.t
```

### Test Data

Test artifacts are located in the `data/` directory. These are actual QIIME 2 artifacts used for testing.

### Writing Tests

Use `Test::More`:

```perl
use Test::More;
use Qiime2::Artifact;

my $artifact = Qiime2::Artifact->new({
    filename => 't/data/test.qza'
});

ok($artifact->get('loaded'), 'Artifact loaded successfully');
is($artifact->get('version'), '2023.5.0', 'Correct version');

done_testing;
```

## Code Style

### General Guidelines

```perl
# Good
sub my_method {
    my ($self, $args) = @_;

    return $self->{attribute};
}

# Private methods
sub _internal_method {
    my ($self) = @_;
    # ...
}
```

### Error Handling

Use `Carp::confess`:

```perl
use Carp qw(confess);

sub my_method {
    my ($self, $required_param) = @_;

    confess "Parameter required" unless defined $required_param;

    # ...
}
```

### Documentation

Add POD documentation:

```perl
=head2 my_method

Description of the method.

B<Parameters:>

=over 4

=item * C<$param1> - Description

=back

B<Returns:> Description

B<Example:>

    my $result = $obj->my_method($param1);

=cut

sub my_method {
    # implementation
}
```

## Reporting Issues

### Bug Reports

When reporting bugs, please include:

1. Perl version (`perl -v`)
2. Module version
3. Operating system
4. Minimal code to reproduce the issue
5. Expected vs. actual behavior
6. Error messages (if any)

### Feature Requests

When requesting features:

1. Describe the use case
2. Explain why it would be useful
3. Suggest an API if possible

## Release Process

(For maintainers)

1. Update version in `lib/Qiime2/Artifact.pm`
2. Update `Changes` file
3. Run all tests: `dzil test`
4. Build distribution: `dzil build`
5. Release: `dzil release`

## Resources

- [GitHub Repository](https://github.com/telatin/qiime2tools)
- [Issue Tracker](https://github.com/telatin/qiime2tools/issues)
- [CPAN Page](https://metacpan.org/pod/Qiime2::Artifact)
- [Project Wiki](https://github.com/telatin/qiime2tools/wiki)

## Code of Conduct

Please be respectful and constructive in all interactions. We want to maintain a welcoming environment for all contributors.

## License

By contributing, you agree that your contributions will be licensed under the same terms as the project (Perl Artistic License).

## Questions?

If you have questions about contributing, please:

1. Check existing issues and documentation
2. Open a new issue with the "question" label
3. Contact the maintainer: Andrea Telatin

Thank you for contributing! 🎉
