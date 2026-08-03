#!/bin/bash 

#SBATCH -J rnaseq
#SBATCH -n 1
#SBATCH -N 1
#SBATCH -c 16
#SBATCH -o logs/%x.%J.out
#SBATCH -e logs/%x.%J.err
#SBATCH --mem=98304
#SBATCH -p standard 
#SBATCH -A imarazzi_lab

set -eou pipefail
exec 1>&2

# set -x  # print each command as it executes
trap 'echo "Error on line $LINENO"' ERR  # print line number on error

sample_id=$1
config=$2

# 1. Loading software
echo "Loading environment..."
module load miniconda3/24.9.2 singularity/3.11.3 
source $config
source $functions_file
module load sra-tools/3.0.0 # newer version of sra doesn't work for downloading FASTQs

# 2. Download fastqs
cmd="rm -rf ${TMPDIR}/tmp.*"
echo $cmd; eval $cmd

SCRDIR=`mktemp -d ${TMPDIR}/tmp.XXXXXX`
# SCRDIR=/tmp/jennipn6/50313511/tmp.QUvvwu

if [ ! -d ${outdir}/${sample_id}/logs ]; then mkdir -p ${outdir}/${sample_id}/logs; fi
log=${outdir}/${sample_id}/logs/pipeline.log

cmd="cd $SCRDIR; mkdir -p ${SCRDIR}/input"
run_cmd "$log"

if [[ $fastq_source == "dropbox" ]]; then
    download_from_dropbox "$sample_id" "$download_file"
fi

if [[ $fastq_source == "geo" ]]; then
    prefetch_and_dump $sample_id $SCRDIR
    cmd="rsync *.fastq.gz $fastq_dir"
    run_cmd "$log"
fi