#!/bin/bash 

#SBATCH -J chipseq 
#SBATCH -n 1
#SBATCH -N 1
#SBATCH -c 12
#SBATCH -o logs/%x.%J.out
#SBATCH -e logs/%x.%J.err
#SBATCH --mem=49152
#SBATCH -p free 
#SBATCH -A imarazzi_lab
#SBATCH --constraint=fastscratch
#SBATCH --tmp=200G

config=$1
sampid=$2
input_sample=$3

# exit on error (-e), pipeline fail detection (-o pipefail), unset variables (-u)
set -eou pipefail
exec 1>&2

# read inputs
source $config

# read helper functions
source ~/personal/helpers/functions.sh
if [ -f ${outdir}/${sampid}/logs/pipeline.log ]; then rm ${outdir}/${sampid}/logs/pipeline.log; fi
if [ -f ${outdir}/${sampid}/logs/run.log ]; then rm ${outdir}/${sampid}/logs/run.log; fi
log=${outdir}/${sampid}/logs/run.log

# make tmp dir
SCRDIR=`mktemp -d -p $TMPDIR`
cmd="cd $SCRDIR; mkdir -p input"
run_cmd "$log"

# activate conda environment
# conda create -n chip-pipeline
# conda install bioconda::bwa=0.7.19 bioconda::samtools=1.23 bioconda::picard=3.4.0 
# conda install bioconda::fastqc=0.12.1 bioconda::trim-galore=0.6.10 bioconda::bedtools=2.31.1 bioconda::deeptools=3.5.6
# conda install bioconda::multiqc=1.33
cmd="module load miniconda3/24.9.2; source activate chip-pipeline"
run_cmd "$log"

# copy inputs
cmd="rsync -rtvL $genome_fasta input/genome.fasta.gz && gunzip input/genome.fasta.gz"
run_cmd "$log"

cmd="rclone copy 'dropbox:${reference_dropbox_path}' local:input --include ${genome_prefix}.tar.gz --transfers 4 --no-gzip-encoding --multi-thread-streams 4"
run_cmd "$log"

cmd="wget -L $blacklist -O input/blacklist.bed.gz && gunzip input/blacklist.bed.gz; sed 's/^chr//' input/blacklist.bed > input/blacklist.nochr.bed; rm input/blacklist.bed; mv input/blacklist.nochr.bed input/blacklist.bed"
run_cmd "$log"

cmd="rsync -rtvL ${fastqdir}/${sampid} input"
run_cmd "$log"

cmd="rsync -rtvL $genebody_bed input/genebody.bed; rsync -rtvL $md5input_filename input"
run_cmd "$log"

cmd="tree input; cd input"
run_cmd "$log"

cmd="md5sum -c --ignore-missing $md5input_filename"
printf '* [%s] Running CMD: %s\n' "$(date)" "$cmd" >> $log
printf '* [%s] Running CMD: %s\n' "$(date)" "$cmd" >& 2

md5input_filename=`basename $md5input_filename`
if ! md5sum -c --ignore-missing $md5input_filename; then
    echo "Error: MD5 checksum verification failed" >&2
    exit 2  
fi

# untar reference
cmd="tar -xvzf ${genome_prefix}.tar.gz; cd $SCRDIR"
run_cmd "$log"

# downsample
if [ $test == "true" ]; then
    echo "Downsampling reads..."
    fastq_files=(input/${sampid}/*.fastq.gz)
    for fastq in "${fastq_files[@]}"; do
        if [ -f "$fastq" ]; then
            echo "Downsampling $fastq"
            basename=$(basename "$fastq" .fastq.gz)
            
            cmd="zcat $fastq | head -32000 > input/${sampid}/dnsamp_${basename}.fastq || true"
            run_cmd "$log"
            
            cmd="gzip input/${sampid}/dnsamp_${basename}.fastq"
            run_cmd "$log"
            
            # replace original 
            cmd="mv input/${sampid}/dnsamp_${basename}.fastq.gz $fastq"
            run_cmd "$log"
        fi
    done
fi

cmd="sh $pipeline $config $sampid $SCRDIR $input_sample"
run_cmd "$log"

cmd="rclone copy local:${outdir}/${sampid}/logs 'dropbox:${dropbox_outdir}/${sampid}/logs' --no-gzip-encoding --transfers 4 --multi-thread-streams 4"
run_cmd "$log"

# cmd="rclone copy local:${outdir}/${sampid}/logs/pipeline.log 'dropbox:${dropbox_outdir}/${sampid}' --no-gzip-encoding --transfers 4 --multi-thread-streams 4"
# run_cmd "$log"

# cmd="rclone copy local:${outdir}/${sampid}/logs/run.log 'dropbox:${dropbox_outdir}/${sampid}' --no-gzip-encoding --transfers 4 --multi-thread-streams 4"
# run_cmd "$log"

# cmd="rclone copy local:${outdir}/${sampid}/logs/chip-pipeline.stdout 'dropbox:${dropbox_outdir}/${sampid}' --no-gzip-encoding --transfers 4 --multi-thread-streams 4"
# run_cmd "$log"

# cmd="rclone copy local:${outdir}/${sampid}/logs/chip-pipeline.stderr 'dropbox:${dropbox_outdir}/${sampid}' --no-gzip-encoding --transfers 4 --multi-thread-streams 4"
# run_cmd "$log"

echo "Done." >> $log
echo "Done." >& 2







