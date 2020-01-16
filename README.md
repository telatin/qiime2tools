# Qiime2 Tools
Repository of utilities for Qiime2. Experimental.

Qiime 2.0 is a complete rewrite of Qiime, and introduces the concept of artifacts to simplify the workflow, tracking metadata and provenance. This 
repository is used to store experimental scripts to inspect or manipulate such artifacts.

## Scripts

### qzoom.pl
Updated utility to extract data from Qiime 2 artifacts. See 
[qzoom_documentation.html](https://htmlpreview.github.io/?https://github.com/telatin/qiime2tools/blob/master/docs/qzoom_documentation.html).

It works independently from Qiime2, its meant to automate common tasks (e.g. extract /.biom/ file and automatically converts it to /.tsv/ if the 
`biom`tool is available).  

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

## 
## Legacy scripts
Some scripts were developed using Qiime2 2017.x, and they are now deprecated.

### extract_data_from_artifact.pl
Extracts the content of the 'data' directory in the artifact in a destination folder.

```
extract_data_from_artifact.pl [options] artifact1 artifact2 ... 

 -d, --destination           Destination directory (default: ./)
 -b, --basename              Use as subdirectory name the artifact file name instead of its UUID
```

Example:
* extract_data_from_artifact.pl --basename --destination q2files *.qza

### gvl_publish_qzv.pl
Extract the visualization of a Qiime 2 artifact (.qzv) to the public HTML directory of a
GVL Virtual Server.

The result will be a public URL like http://YOUR_IP/public/researcher/qiime2/ARTIFACT_ID.

