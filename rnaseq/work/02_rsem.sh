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
fi