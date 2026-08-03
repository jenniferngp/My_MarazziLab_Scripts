#!/bin/bash

#SBATCH --job-name=sra            ## job name
#SBATCH -A imarazzi_lab           ## account to charge 
#SBATCH -p free                   ## partition name
#SBATCH -N 1                      ## run on a single node, cant run across multiple nodes
#SBATCH --ntasks=8                ## CPUs to use as threads in fasterq-dump command
#SBATCH --tmp=100G                ## requesting 100 GB local scratch
#SBATCH --constraint=fastscratch  ## requesting nodes with fast scratch in /tmp

# IMPORTANT: load the latest SRA-tools, earlier versions do not handle temporary disk
# module load miniconda3/24.9.2 
# source activate chip-pipeline
module load sra-tools/3.0.0

SCRDIR=`mktemp -d -p $TMPDIR`
cd $SCRDIR 

ID=$1
outdir=$2

prefetch $ID

# convert sra format to fastq format using requested number of threads (slurm tasks)
# an accession number is specified as a directory 
# temp files are written to fastscratch in $TMPDIR with a 100G limit
fasterq-dump ./$ID -e $SLURM_NTASKS --temp $SCRDIR --disk-limit-tmp 100G  

# compress resulting fastq files
gzip $ID*fastq

# move all results to desired location in DFS, directory must exists
mv *fastq.gz $outdir