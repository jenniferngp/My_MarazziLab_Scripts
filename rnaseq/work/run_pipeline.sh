#!/bin/bash 

#SBATCH -J rnaseq
#SBATCH -n 1
#SBATCH -N 1
#SBATCH -c 24
#SBATCH -o logs/%x.%J.out
#SBATCH -e logs/%x.%J.err
#SBATCH --mem=147456
#SBATCH -p standard 
#SBATCH --tmp=200G
#SBATCH --constraint=fastscratch
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

log=${workdir}/${project_id}/${run_id}/sample/${sample_id}/logs/pipeline.log

cmd="cd $SCRDIR; mkdir -p ${SCRDIR}/input"
run_cmd "$log"

if [[ $fastq_source == "dropbox" ]]; then
    download_from_dropbox "$sample_id" "$download_file"
fi

if [[ $fastq_source == "geo" ]]; then
    prefetch_and_dump $sample_id $SCRDIR
    cmd="mv *.fastq.gz input"
    run_cmd "$log"
fi

if [[ $fastq_source == "hpc3" ]]; then
    cmd="rsync ${fastq_dir}/${sample_id}/*.fastq.gz input"
    run_cmd "$log"
fi

source activate $conda_environment

# 3. Downsample if testing pipeline
if [[ $test_pipeline == "true" ]]; then
    for fq in input/*.fastq.gz; do
        downsample_fastq "$fq"
    done
fi

# 4. Copy parameters (run.yml)
cmd="rsync $params $SCRDIR"
run_cmd "$log"

# 5. Copy reference
if [[ $reference_location == "dropbox" ]]; then
    if [ ! -f $reference_prefix ]; then
        cmd="rclone copy 'dropbox:${reference_path}/${reference_prefix}' local: --no-gzip-encoding --transfers=4 --multi-thread-streams=4; mv $reference_prefix star_reference.tar.gz"
        run_cmd "$log"
    fi
fi

tree

# 4. Run pipeline
cmd="nextflow run ${nf_pipeline} -params-file run.yml --workdir $SCRDIR -resume -with-report report.html"
run_cmd "$log"

# # 5. Copy commands
# mkdir -p results/commands
# for first in work/*; do
#     for sec in ${first}/*; do
#         basefirst=`basename $first`
#         basesec=`basename $sec`
#         rsync ${sec}/.command.sh  results/commands/cmd_${basefirst}_${basesec}.sh
#         rsync ${sec}/.command.log results/commands/cmd_${basefirst}_${basesec}.log
#         rsync ${sec}/.command.out results/commands/cmd_${basefirst}_${basesec}.out
#         rsync ${sec}/.command.err results/commands/cmd_${basefirst}_${basesec}.err
#         rsync ${sec}/.command.run results/commands/cmd_${basefirst}_${basesec}.run
#     done
# done

# # 6. Clean (optional)
# cmd="rm -r results/*/*/*.bam{,.bai}"
# run_cmd "$log"

# 7. Generate md5sum
cmd="cd ${SCRDIR}/results; find . -type f ! -name "MD5.txt" -exec md5sum {} \; > MD5.txt; cd $SCRDIR"
run_cmd "$log"

# 8. Rename
cmd="mv report.html results; mv results $sample_id; cd $sample_id; multiqc --ai-summary-full -d --force --fullnames .; cd $SCRDIR"
run_cmd "$log"

# 9. Copy output to outdir
cmd="rsync -rvl $sample_id $outdir"
run_cmd "$log"

# 10. Check md5sum
cmd="cd ${outdir}/${sample_id}; md5sum -c ${outdir}/${sample_id}/MD5.txt"
run_cmd "$log"

echo "Done!" >&2
