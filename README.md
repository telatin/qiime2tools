# Qiime2 Tools

Repository of utilities for Qiime2. Experimental.

Qiime 2.0 is a complete rewrite of Qiime, and introduces the concept of artifacts to simplify the workflow, tracking metadata and provenance. This repository is used to store experimental scripts to inspect or manipulate such artifacts.


### Downloading this repository

From the command line type the following command from the directory you want to have the repository copied in:

```
git clone https://github.com/telatin/qiime2tools/
```
Keep note of the installation directory, I'll refer to as `$INSTALLDIR`.

### Running a script from this repository
From the command line:

``` 
perl $INSTALLDIR/qiime2tools/script_name.pl 
```

### Scripts

#### gvl_publish_qzv.pl

Extract the visualization of a Qiime 2 artifact (.qzv) to the public HTML directory of a 
<a href="https://nectar.org.au/?portfolio=genomics-virtual-lab">GVL Virtual Server</a>.

The result will be a public URL like <em>http://YOUR_IP/public/researcher/qiime2/ARTIFACT_ID</em>.


