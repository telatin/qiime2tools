

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

