#!/bin/bash
#SBATCH -J coverage
#SBATCH -c 12
#SBATCH -p free
#SBATCH -A imarazzi_lab 

set -eou pipefail
exec 1>&2

cd $TMPDIR

sample_id=$1
bamdir=$2
outdir=$3

bam=${bamdir}/${sample_id}.bam
filt=${bamdir}/${sample_id}.filt.bam

module load miniconda3/24.9.2 samtools/1.15.1

if [ ! -f ${filt}.bai ]; then
    cmd="samtools view -F 2316 -q 10 -b $bam > $filt"
    echo $cmd; eval $cmd
    # -F 2316 = 4 + 8 + 256 + 2048 (unmapped + mate unmapped + secondary + supplementary)
    
    cmd="samtools index $filt"
    echo $cmd; eval $cmd
fi

if [ ! -f ${bam}.bai ]; then
    cmd="samtools index $bam"
    echo $cmd; eval $cmd
fi

source activate /dfs8/imarazzi_lab/share/jennifer/envs/rna-pipeline

# FOR dUTP LIBRARY (most common stranded RNA-seq)
# Plus strand = read2 NOT reverse + read1 reverse
samtools view -f 128 -F 16 -b $filt -o tmp_plus1.bam
samtools view -f 80 -b $filt -o tmp_plus2.bam  # flag 80 = read1 + reverse
samtools merge -f plus.bam tmp_plus1.bam tmp_plus2.bam
samtools sort -o plus.sorted.bam plus.bam
samtools index plus.sorted.bam

# Minus strand = read1 NOT reverse + read2 reverse
samtools view -f 64 -F 16 -b $filt -o tmp_minus1.bam
samtools view -f 144 -b $filt -o tmp_minus2.bam  # flag 144 = read2 + reverse
samtools merge -f minus.bam tmp_minus1.bam tmp_minus2.bam
samtools sort -o minus.sorted.bam minus.bam
samtools index minus.sorted.bam

# bigwigs
cmd="bamCoverage --numberOfProcessors 12 --binSize 10 \
--normalizeUsing RPKM --skipNonCoveredRegions \
--bam plus.sorted.bam --outFileName ${sample_id}.plu.bw"
echo $cmd; eval $cmd

cmd="bamCoverage --numberOfProcessors 12 --binSize 10 \
--normalizeUsing RPKM --skipNonCoveredRegions \
--bam minus.sorted.bam --outFileName ${sample_id}.neg.bw"
echo $cmd; eval $cmd
    
# cmd="bamCoverage \
# --outFileFormat bigwig \
# --skipNonCoveredRegions \
# --numberOfProcessors 12 \
# --binSize 10 \
# --normalizeUsing RPKM \
# --bam $filt \
# --outFileName ${sample_id}.bw"
# echo $cmd; eval $cmd

cmd="rsync *.bw $outdir"
echo $cmd; eval $cmd