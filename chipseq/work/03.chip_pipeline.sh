#!/bin/bash 

#SBATCH -J chipseq 
#SBATCH -n 1
#SBATCH -N 1
#SBATCH -c 12
#SBATCH --mem=49152
#SBATCH -p free 
#SBATCH -A imarazzi_lab
#SBATCH --constraint=fastscratch
#SBATCH --tmp=200G

config=$1
sampid=$2
SCRDIR=$3
input_sample=$4
ip_molecule=$5

set -eou pipefail
exec 1>&2

# read helper functions
source $config
source ~/personal/helpers/functions.sh
log=${outdir}/${sampid}/logs/pipeline.log

# extract input bam
if [[ "$input_sample" != "none" ]]; then
    if [ ! -f ${outdir}/${input_sample}/output/02.bwa/filtered_blacklist.bam ]; then
        cmd="cd ${outdir}/${input_sample}"
        run_cmd "$log"
        cmd="tar -xvzf output.tar.gz output/02.bwa/filtered_blacklist.bam"
        run_cmd "$log"
        cmd="tar -xvzf output.tar.gz output/02.bwa/filtered_blacklist.bam.bai"
        run_cmd "$log"
    fi
fi

# initialize 
cmd="cd $SCRDIR; mkdir -p 01.fastqc 02.bwa 03.qc/flagstat 03.qc/picard 03.qc/spp 03.qc/pbc 04.deeptools/coverage 04.deeptools/plots"
run_cmd "$log"

# fastqc
shopt -s nullglob; files=(input/${sampid}/*.{fq,fastq}.gz); shopt -u nullglob
cmd="fastqc -o 01.fastqc ${files[@]}"
run_cmd "$log"

# trim adapters (auto-detection mode)
if [[ "$libtype" == "paired" ]]; then
    cmd="trim_galore --paired --cores 8 --output_dir trim_galore ${files[@]}"
    run_cmd "$log"
else
    cmd="trim_galore --cores 8 --output_dir trim_galore ${files[@]}"
    run_cmd "$log"
fi

# check adapters are removed 
cmd="fastqc -o 01.fastqc trim_galore/*.{fq,fastq}.gz"
run_cmd "$log"

# align reads
shopt -s nullglob; files=(trim_galore/*.{fq,fastq}.gz); shopt -u nullglob
cmd="bwa mem -R '@RG\tID:RG1\tSM:"${sampid}"\tPL:PLATFORM\tLB:${sampid}\tPU:UNIT' -t 12 input/${genome_prefix}/${genome_prefix} ${files[@]} > aligned.sam" 
run_cmd "$log"

# convert sam to bam
cmd="samtools view -@ 10 -bS -u aligned.sam | samtools sort -@ 10 - -o 02.bwa/aligned.bam"
run_cmd "$log"

# mark duplicates
cmd="picard MarkDuplicates \
I=02.bwa/aligned.bam \
O=02.bwa/mkdup.bam \
M=03.qc/picard/dup_metrics.txt \
REMOVE_DUPLICATES=false \
VALIDATION_STRINGENCY=LENIENT"
run_cmd "$log"

# filter reads based on encode3 pipeline: 
# remove: reads unmapped, mate unmapped, not primary alignment, read fails, duplicates, min MAPQ < 30 (-q)
cmd="samtools view -@ 4 -b -F 1804 -q 30 02.bwa/mkdup.bam > 02.bwa/filtered_temp.bam"
run_cmd "$log"

# remove reads with insert sizes > 2kb (recommended by literature)
# keep reads that are prop-paired
# only for paired reads
if [[ "$libtype" == "paired" ]]; then
    cmd="samtools view -@ 4 -h -f 2 02.bwa/filtered_temp.bam | \
        awk -v max=2000 '\$1 ~ /^@/ || \$9 == 0 || (\$9 <= max && \$9 >= -max)' | \
        samtools view -@ 4 -b > 02.bwa/filtered.bam"
    run_cmd "$log"
else
    cmd="mv 02.bwa/filtered_temp.bam 02.bwa/filtered.bam"
    run_cmd "$log"
fi

# for paired-end - I don't use this because it outputs a truncated bam that couldn't be used for bamCoverage
# cmd="bamtools filter -in filtered_blacklist.bam \
#         -insertSize '<2000' \
#         -isProperPair true \
#         -isMapped true \
#         -isDuplicate false \
#         -tag 'NM:<5' > filtered_bamtools.bam"
# cmd="samtools index align/05.filtered_bamtools.bam"
# echo $cmd; echo $cmd >&2; eval $cmd

# remove reads in blacklisted regions
cmd="bedtools intersect -v -abam 02.bwa/filtered.bam -b input/blacklist.bed > 02.bwa/filtered_blacklist.bam"
run_cmd "$log"

# index bam
cmd="samtools index 02.bwa/filtered_blacklist.bam"
run_cmd "$log"

# qc samtools stats
for bam in 02.bwa/*.bam; do
    name=`basename $bam`
    if [ ! -f ${bam}.bai ]; then samtools index ${bam}; fi
    cmd="samtools flagstat $bam > 03.qc/flagstat/${name}.flagstat"
    run_cmd "$log"
    cmd="samtools idxstats $bam > 03.qc/flagstat/${name}.idxstat"
    run_cmd "$log"
    cmd="samtools stats $bam > 03.qc/flagstat/${name}.stat"
    run_cmd "$log"
done

# qc picard insert size
cmd="picard CollectInsertSizeMetrics \
I=02.bwa/filtered_blacklist.bam \
O=03.qc/picard/insert_size_metrics.txt \
H=03.qc/picard/insert_size_histogram.pdf \
M=0.5"
run_cmd "$log"

# compute lib complexity (from encode)
bamfile=02.bwa/filtered_blacklist.bam 
pbc_qc=03.qc/pbc/filtered_blacklist.pbc_qc
if [[ "$test" == "paired" ]]; then
    cmd="echo -e 'TotalReadPairs\tDistinctReadPairs\tOneReadPair\tTwoReadPairs\tNRF\tPBC1\tPBC2' > ${pbc_qc}; bedtools bamtobed -i ${bamfile} | awk 'BEGIN{OFS=\"\t\"}{print \$1,\$2,\$3,\$6}' | grep -v 'MT' | grep -v 'chrM' | grep -v 'chrMT' | sort | uniq -c | awk 'BEGIN{mt=0;m0=0;m1=0;m2=0} (\$1==1){m1=m1+1} (\$1==2){m2=m2+1} {m0=m0+1} {mt=mt+\$1} END{printf \"%d\t%d\t%d\t%d\t%f\t%f\t%f\n\",mt,m0,m1,m2,m0/mt,m1/m0,m1/m2}' >> ${pbc_qc}"
    run_cmd "$log"
else
    cmd="echo -e 'TotalReadPairs\tDistinctReadPairs\tOneReadPair\tNRF\tPBC1\tPBC2' > ${pbc_qc}; bedtools bamtobed -i ${bamfile} | awk 'BEGIN{OFS=\"\t\"}{print \$1,\$2,\$3}' | grep -v 'MT' | grep -v 'chrM' | grep -v 'chrMT' | sort | uniq -c | awk 'BEGIN{mt=0;m0=0;m1=0;m2=0} (\$1==1){m1=m1+1} (\$1==2){m2=m2+1} {m0=m0+1} {mt=mt+\$1} END{printf \"%d\t%d\t%d\t%d\t%f\t%f\t%f\n\",mt,m0,m1,m2,m0/mt,m1/m0,m1/m2}' >> ${pbc_qc}"
    run_cmd "$log"
fi

# run spp 
ccplot=03.qc/spp/cc_plot.pdf
ccscores=03.qc/spp/cc_scores.txt
EXCLUSION_RANGE_MIN=-500
buffer=$((readlength + 10))
if [[ "$ip_molecule" == "Histone" ]]; then
    if [ $buffer -gt 100 ]; then
        EXCLUSION_RANGE_MAX=$buffer
    else
        EXCLUSION_RANGE_MAX=100
    fi
else
    if [ $buffer -gt 50 ]; then
        EXCLUSION_RANGE_MAX=$buffer
    else
        EXCLUSION_RANGE_MAX=50
    fi
fi
ipbam=02.bwa/filtered_blacklist.bam
module load R/4.3.3 
cmd="Rscript $run_spp_script -c=$ipbam -p=8 -filtchr=M -savp=$ccplot -out=$ccscores -x=${EXCLUSION_RANGE_MIN}:${EXCLUSION_RANGE_MAX}"
run_cmd "$log"
module unload R/4.3.3 

# generate bigwig
spplog=03.qc/spp/cc_scores.txt
fragment_length=$(cat ${spplog} | awk '{print $3}' | cut -d',' -f1)
    
cmd="bamCoverage \
--normalizeUsing RPKM \
--binSize 10 \
--bam 02.bwa/filtered_blacklist.bam \
--numberOfProcessors 8 \
--extendReads $fragment_length \
--outFileName 04.deeptools/coverage/${sampid}.rpkm.with_fraglen.bw"
run_cmd "$log"

cmd="bamCoverage \
--normalizeUsing RPKM \
--binSize 10 \
--bam 02.bwa/filtered_blacklist.bam \
--numberOfProcessors 8 \
--outFileName 04.deeptools/coverage/${sampid}.rpkm.bw"
run_cmd "$log"

# plot gene body coverage
cmd="computeMatrix scale-regions \
-R input/genebody.bed \
-S 04.deeptools/coverage/${sampid}.rpkm.bw \
--beforeRegionStartLength 3000 \
--afterRegionStartLength 3000 \
--regionBodyLength 3500 \
--sortRegions descend \
--sortUsing mean \
--missingDataAsZero \
--blackListFileName input/blacklist.bed \
--numberOfProcessors 8 \
--outFileName 04.deeptools/coverage/filtered_blacklist.rpkm.matrix.gz"
run_cmd "$log"

cmd="plotHeatmap \
-m 04.deeptools/coverage/filtered_blacklist.rpkm.matrix.gz \
--outFileName 04.deeptools/plots/genebody_coverage.pdf \
--sortUsing mean \
--sortRegions descend \
--colorMap Blues \
--heatmapHeight 10 \
--heatmapWidth 7 \
--outFileNameMatrix 04.deeptools/coverage/filtered_blacklist.rpkm.matrix.sorted.gz"
run_cmd "$log"

# clean 
# cmd="rm -rf 02.bwa/aligned.bam 02.bwa/mkdup.bam 02.bwa/filtered.bam 02.bwa/filtered_temp.bam aligned.sam"
cmd="rm -rf 02.bwa/aligned.bam{,.bai} 02.bwa/filtered.bam{,.bai} 02.bwa/filtered_temp.bam{,.bai} aligned.sam"
run_cmd "$log"

# call peaks
if [[ "$input_sample" != "none" ]]; then

    ipbam=02.bwa/filtered_blacklist.bam
    inputbam=${outdir}/${input_sample}/output/02.bwa/filtered_blacklist.bam
    cmd="mkdir -p 05.macs3"
    run_cmd "$log"

    cmd="macs3 callpeak \
    -t $ipbam \
    -c $inputbam \
    --nomodel \
    --extsize $fragment_length \
    --keep-dup all \
    -g $gs \
    -q ${qthresh} \
    -n 05.macs3/keepdup_nomodel_q${qthresh}_broadq${broad_qthresh} \
    --broad \
    --broad-cutoff ${broad_qthresh}"

    if [[ "$libtype" == "paired" ]]; then cmd="$cmd -f BAMPE"; else cmd="${cmd} -f BAM"; fi
    
    run_cmd "$log"
        
    cmd="macs3 callpeak \
    -t $ipbam \
    -c $inputbam \
    --nomodel \
    --extsize $fragment_length \
    --keep-dup all \
    -g $gs \
    -q ${qthresh} \
    -n 05.macs3/keepdup_nomodel_q${qthresh}"

    if [[ "$libtype" == "paired" ]]; then cmd="$cmd -f BAMPE"; else cmd="${cmd} -f BAM"; fi
    
    run_cmd "$log"
    
    
fi

# calculate frip
if [[ "$input_sample" != "none" ]]; then
    cmd="mkdir -p 04.deeptools/plotenrichment"
    run_cmd "$log"

	cmd="plotEnrichment -b 02.bwa/filtered_blacklist.bam --BED 05.macs3/keepdup_nomodel_q${qthresh}_broadq${broad_qthresh}_peaks.broadPeak --outRawCounts 04.deeptools/plotenrichment/keepdup_nomodel_q${qthresh}_peaks.broadPeak.frip_counts.tab"
	run_cmd "$log"

	cmd="plotEnrichment -b 02.bwa/filtered_blacklist.bam --BED 05.macs3/keepdup_nomodel_q${qthresh}_peaks.narrowPeak --outRawCounts 04.deeptools/plotenrichment/keepdup_nomodel_q${qthresh}_peaks.narrowPeak.frip_counts.tab"
	run_cmd "$log"
fi

# rearrange files
if [[ "$input_sample" == "none" ]]; then
    cmd="mkdir -p output; mv 01.fastqc 02.bwa 03.qc 04.deeptools output; cd output; multiqc .; cd $SCRDIR"
    run_cmd "$log"
else
    cmd="mkdir -p output; mv 01.fastqc 02.bwa 03.qc 04.deeptools 05.macs3 output; cd output; multiqc .; cd $SCRDIR"
    run_cmd "$log"
fi

cmd="tar -cvzf output.tar.gz output"
run_cmd "$log"

# make md5sum
cmd="md5sum output.tar.gz > MD5_output.txt"
run_cmd "$log"

cmd="cd input; find -type f ! -name MD5_pipeline_input.txt -exec md5sum '{}' \; > MD5_pipeline_input.txt; cd $SCRDIR"
run_cmd "$log"

# transfer to outdir
if [[ "$save_to_hpc3" == "yes" ]]; then
    cmd="rsync -rtvL output.tar.gz MD5_output.txt input/MD5_pipeline_input.txt ${outdir}/${sampid}"
    run_cmd "$log"
fi

# upload to dropbox
if [[ "$upload_to_dropbox" == "yes" ]]; then

    cmd="rclone mkdir 'dropbox:${dropbox_outdir}/${sampid}'"
    run_cmd "$log"
    
    cmd="rclone copy local:output.tar.gz 'dropbox:${dropbox_outdir}/${sampid}' --no-gzip-encoding --transfers 4 --multi-thread-streams 4"
    run_cmd "$log"

    cmd="rclone copy local:MD5_output.txt 'dropbox:${dropbox_outdir}/${sampid}' --no-gzip-encoding --transfers 4 --multi-thread-streams 4"
    run_cmd "$log"

    cmd="rclone copy local:input/MD5_pipeline_input.txt 'dropbox:${dropbox_outdir}/${sampid}' --no-gzip-encoding --transfers 4 --multi-thread-streams 4"
    run_cmd "$log"
fi

cmd="echo Done."
run_cmd "$log"

echo "Done." >& 2


