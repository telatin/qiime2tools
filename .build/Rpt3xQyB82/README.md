# Qiime2 Tools
Repository of utilities for Qiime2. Experimental.

Qiime 2.0 is a complete rewrite of Qiime, and introduces the concept of artifacts to simplify the workflow, tracking metadata and provenance. This 
repository is used to store experimental scripts to inspect or manipulate such artifacts.



## :package: qzoom.pl
Updated utility to extract data from Qiime 2 artifacts. 
See [qzoom documentation](https://github.com/telatin/qiime2tools/blob/master/docs/qzoom_readme.md).

It works independently from Qiime2, its meant to automate common tasks 
(e.g. extract .*biom* file and automatically converts it to .*tsv* if the `biom` tool is available).  

### Example usage

Extract a set of visualizations into a directory. A subdirectory with the name of the visualization file will be created for each "qzv" artifact:
```
qzoom.pl -x -o ./html *.qzv
```
View the main file contained in each artifact:

```
qzoom.pl  *.qz?
```
### Default mode: "ls" like


Screenshot in *info* mode:
![Screenshot](docs/qzoom.png)

### Extract mode

In extract mode we want to extract the content of the `data` directory for regular artifacts (*qza*), the whole HTML directory for visualizations (*qzv*).

Combining `-x` (extract) with `-r` (rename), will extract the single file of the data directory getting the name from the artifact.

![Extract](docs/extract.png)

## Downloading this repository
From the command line type the following command from the directory you want to have the repository copied in:

```
git clone https://github.com/telatin/qiime2tools/
```
Keep note of the installation directory, I'll refer to as `$INSTALLDIR`.

#### Running a script from this repository
From the command line:

```
perl $INSTALLDIR/qiime2tools/script_name.pl 
```