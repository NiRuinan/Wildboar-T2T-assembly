#!/bin/bash

# bowtie2_self
for i in 1 2 3 "in"
do
  bowtie2 -p 32 --very-sensitive --no-mixed --no-discordant -k 10 \
    -x sample.fa \
    -1 sample_${i}_clean_1.fastq.gz \
    -2 sample_${i}_clean_2.fastq.gz \
  | samtools sort -O bam -@ 32 -o sample.sample_${i}.bam
done

for i in 1 2 3 "in"
do
  picard MarkDuplicates \
    --INPUT sample.sample_${i}.bam \
    --OUTPUT sample.sample_${i}.rmdup.bam \
    --METRICS_FILE sample.sample_${i}.dup_metrics.txt \
    --REMOVE_DUPLICATES true

  samtools index sample.sample_${i}.rmdup.bam

  bamCoverage \
    --bam sample.sample_${i}.rmdup.bam \
    --outFileName sample.sample_${i}.rmdup.bw \
    --outFileFormat bigwig \
    --binSize 5 -p 32
done

# call peak
macs3 callpeak \
  -t sample_1.bam sample_2.bam sample_3.bam \
  -c sample_in.bam \
  -f BAMPE \
  -g 2.7e9 \
  -B -q 0.05 \
  -n sample

macs3 bdgcmp 
  -t sample_treat_pileup.bdg \
  -c sample_control_lambda.bdg \
  --outdir ./ \
  -o sample_logFE.bdg \
  -m logFE \
  -p 0.00001
