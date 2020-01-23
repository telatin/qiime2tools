#!/bin/bash
set -euox pipefail

# Single ends directory


# SETTINGS Mapping file
MAPPING='mapping.tsv'
MANIFEST='manifest.txt'
OUTPUT='qiime2_analysis'
TREATMENT='Treatment'
TYPE='SampleData[SequencesWithQuality]'
FMT=SingleEndFastqManifestPhred33
TRIM=250

# CHECK PARAMETERS
if [ -z ${1+x} ]; then
	echo " ERROR: Specify the input directory, e.g. 'reads'."
	exit
fi

if [ ! -z ${2+x} ]; then
	OUTPUT=$2
	echo " OUTPUT: $OUTPUT"
fi

# CHECK INPUT DIRECTORY EXIST
INPUT="$1"
if [[ ! -d "$INPUT" ]]; then
	echo " ERROR: Input directory not found: $INPUT"
	exit
else
	echo " INPUT: $INPUT"
fi



# GENERATE MANIFEST READS IF NOT
if [[ ! -e "$MANIFEST" ]]; then
        COUNT_READS=0
        echo "sample-id,absolute-filepath,direction" > $MANIFEST;
        for FILE in $INPUT/*.f*; do
                COUNT_READS=$((COUNT_READS + 1));
                CODE=$(basename "$FILE" | cut -f 1 -d "_");
                ABSPATH=$(readlink -f "$FILE");
                echo "$CODE,$ABSPATH,forward" >> $MANIFEST
        done
        echo "Created manifest file: $COUNT_READS SE FASTQ files found"
fi




mkdir -p $OUTPUT/

if [[ ! -e "$OUTPUT/metadata.qzv" ]]; then
 qiime metadata tabulate \
    --m-input-file $MAPPING \
    --o-visualization $OUTPUT/metadata.qzv
fi


if [[ ! -e "$OUTPUT/1_demux-seqs.qza" ]]; then
qiime tools import \
  --type "$TYPE" \
  --input-path $MANIFEST \
  --source-format $FMT \
  --output-path $OUTPUT/1_demux-seqs.qza
fi


if [[ ! -e "$OUTPUT/1_demux-seqs_summarized.qzv" ]]; then
qiime demux summarize \
  --i-data $OUTPUT/1_demux-seqs.qza \
  --o-visualization $OUTPUT/1_demux-seqs_summarized.qzv
fi


if [[ ! -e "$OUTPUT/2_demux-filtered.qza" ]]; then
qiime quality-filter q-score \
 --i-demux $OUTPUT/1_demux-seqs.qza \
 --p-min-quality 17 \
 --o-filtered-sequences $OUTPUT/2_demux-filtered.qza \
 --o-filter-stats $OUTPUT/2_demux-filtered-stats.qza
fi

# 390
if [[ ! -e "$OUTPUT/3_table-deblur.qza" ]]; then
qiime deblur denoise-16S \
  --i-demultiplexed-seqs  $OUTPUT/2_demux-filtered.qza \
  --p-trim-length $TRIM \
  --o-representative-sequences  $OUTPUT/3_rep-seqs-deblur.qza \
  --o-table  $OUTPUT/3_table-deblur.qza \
  --p-sample-stats \
  --o-stats $OUTPUT/3_deblur-stats.qza
fi

if [[ ! -e "$OUTPUT/3B_deblur-stats.qzv" ]]; then
#	qiime metadata tabulate \
#	  --m-input-file $OUTPUT/3_deblur-stats.qza \
#	  --o-visualization $OUTPUT/3B_demux-filter-stats.qzv
	qiime deblur visualize-stats \
	  --i-deblur-stats $OUTPUT/3_deblur-stats.qza \
	  --o-visualization $OUTPUT/3B_deblur-stats.qzv
fi

REPSEQ=$OUTPUT/3_rep-seqs-deblur.qza
TABLE=$OUTPUT/3_table-deblur.qza

if [[ ! -e "$OUTPUT/4_table.qzv" ]]; then
	qiime feature-table summarize \
	  --i-table $TABLE \
	  --o-visualization $OUTPUT/4_table.qzv \
	  --m-sample-metadata-file $MAPPING
fi

if [[ ! -e "$OUTPUT/4_rep-seqs.qzv" ]]; then
	qiime feature-table tabulate-seqs \
	  --i-data $REPSEQ \
	  --o-visualization $OUTPUT/4_rep-seqs.qzv
fi

o="$OUTPUT/5_aligned-rep-seq.qza"
if [[ ! -e $o ]]; then
qiime alignment mafft \
  --i-sequences $REPSEQ \
  --o-alignment $o
fi

o="$OUTPUT/5_masked-aligned-rep-seqs.qza"
if [[ ! -e $o ]]; then
qiime alignment mask \
  --i-alignment "$OUTPUT/5_aligned-rep-seq.qza" \
  --o-masked-alignment $o
fi

o="$OUTPUT/6_unrooted-tree.qza"
if [[ ! -e $o ]]; then
qiime phylogeny fasttree \
  --i-alignment "$OUTPUT/5_masked-aligned-rep-seqs.qza" \
  --o-tree $o
fi

o="$OUTPUT/6_rooted-tree.qza"
if [[ ! -e $o ]]; then
qiime phylogeny midpoint-root \
  --i-tree "$OUTPUT/6_unrooted-tree.qza" \
  --o-rooted-tree $o
fi

DEPTH=50000

if [[ ! -d "$OUTPUT/core-metrics" ]]; then
qiime diversity core-metrics-phylogenetic \
  --i-phylogeny "$OUTPUT/6_rooted-tree.qza" \
  --i-table $TABLE \
  --p-sampling-depth $DEPTH \
  --m-metadata-file $MAPPING \
  --output-dir "$OUTPUT/core-metrics"
fi

o="$OUTPUT/core-metrics/faith-pd-group-significance.qzv"
if [[ ! -e $o ]]; then
qiime diversity alpha-group-significance \
  --i-alpha-diversity "$OUTPUT/core-metrics/faith_pd_vector.qza" \
  --m-metadata-file $MAPPING \
  --o-visualization $o
fi

o="$OUTPUT/core-metrics/evenness-group-significance.qzv"
if [[ ! -e $o ]]; then
qiime diversity alpha-group-significance \
  --i-alpha-diversity "$OUTPUT/core-metrics/evenness_vector.qza" \
  --m-metadata-file $MAPPING \
  --o-visualization $o
fi

# LOOP TREATMNETS
o="$OUTPUT/core-metrics/unweighted-unifrac-treatment-significance.qzv"
if [[ ! -e $o ]]; then
qiime diversity beta-group-significance \
  --i-distance-matrix "$OUTPUT/core-metrics/unweighted_unifrac_distance_matrix.qza" \
  --m-metadata-file $MAPPING \
  --m-metadata-column $TREATMENT \
  --o-visualization $o \
  --p-pairwise
fi


o="$OUTPUT/core-metrics/unweighted-unifrac-emperor-treatment.qzv"
if [[ ! -e $o ]]; then
qiime emperor plot \
  --i-pcoa "$OUTPUT/core-metrics/unweighted_unifrac_pcoa_results.qza" \
  --m-metadata-file $MAPPING \
  --o-visualization $o
fi

# NUMERIC
o="$OUTPUT/core-metrics/bray-curtis-emperor-treatment.qzv"
if [[ ! -e $o ]]; then
qiime emperor plot \
  --i-pcoa "$OUTPUT/core-metrics/bray_curtis_pcoa_results.qza" \
  --m-metadata-file $MAPPING \
  --o-visualization "$o"
 #  --p-custom-axis   $TREATMENT \  #NUMERIC

fi

if [[ ! -e "gg-13-8-99-515-806-nb-classifier.qza" ]]; then
	wget "https://data.qiime2.org/2018.6/common/gg-13-8-99-515-806-nb-classifier.qza"
fi


o="$OUTPUT/taxonomy.qza"
if [[ ! -e $o ]]; then
qiime feature-classifier classify-sklearn \
  --i-classifier gg-13-8-99-515-806-nb-classifier.qza \
  --i-reads $REPSEQ \
  --o-classification "$o"
fi

o="$OUTPUT/taxonomy.qzv"
if [[ ! -e $o ]]; then
qiime metadata tabulate \
  --m-input-file "$OUTPUT/taxonomy.qza" \
  --o-visualization "$o"
fi

o="$OUTPUT/taxa-bar-plots.qzv"
if [[ ! -e $o ]]; then
qiime taxa barplot \
  --i-table "$TABLE" \
  --i-taxonomy "$OUTPUT/taxonomy.qza" \
  --m-metadata-file $MAPPING \
  --o-visualization "$o"
fi

###Differential abundance testing with ANCOM
#  -----------------------------------------------

