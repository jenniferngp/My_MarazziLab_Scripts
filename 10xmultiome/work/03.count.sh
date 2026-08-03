#!/bin/bash

#SBATCH -J cellranger
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 25
#SBATCH --mem=153600
#SBATCH -p standard
#SBATCH -A imarazzi_lab

set -eou pipefail
exec 1>&2

outdir=$1 # /data/homezvol1/jennipn6/lab/jennifer/multiome/processed/sample
sample_id=$2 # BC830_Day6_Liver6
library_metadata=$3 # /data/homezvol1/jennipn6/lab/jennifer/multiome/processed/work/02.libraries.csv
samp2fq=$4 # /data/homezvol1/jennipn6/lab/jennifer/multiome/processed/work/02.sample2fastqs.csv

log=${outdir}/${sample_id}/logs/commands.log

# helper functions
source /dfs6b/pub/jennipn6/helpers/functions.sh

# export cellranger
cmd="export PATH=/dfs6b/pub/jennipn6/software/cellranger-arc-2.1.0:$PATH"
run_cmd "$log"

# make scratch direectory
SCRDIR=`mktemp -d -p $TMPDIR`
cmd="cd $SCRDIR"
run_cmd "$log"

# save output if run into an error
trap '[[ $? -ne 0 ]] && rsync -rtvL ${sample_id}/${sample_id}.mri.tgz ${outdir}/${sample_id} && run_cmd "$log"' EXIT

# copy library metadata
cmd="rsync -rtvL $library_metadata $samp2fq $SCRDIR"
run_cmd "$log"

library_metadata=`basename $library_metadata`
samp2fq=`basename $samp2fq`

# copy reference
cmd="rclone copy 'dropbox:/14. Lab Members/jennifer/reference/personal/cellranger_reference/Mmul10.tar.gz' local: --no-gzip-encoding --transfers 4 --multi-thread-streams 4"
run_cmd "$log"

cmd="tar -xvzf Mmul10.tar.gz"
run_cmd "$log"

# copy fastq and md5sum
cmd="rclone copy 'dropbox:/14. Lab Members/jennifer/projects/utmb/scrna_nhp_data' local: --include *${sample_id}*.fastq.gz --include *md5sums.txt --no-gzip-encoding --transfers 4 --multi-thread-streams 4"
run_cmd "$log"

# check md5sum
cd ${SCRDIR}/Tarani_Run1248_scATAC
if ! md5sum -c --ignore-missing Tarani_Run1248_scATAC-md5sums.txt; then echo "md5sum error!"; exi1; fi

cd ${SCRDIR}/Tarani_Run1247_scRNA
if ! md5sum -c --ignore-missing Tarani_Run1247_scRNA-md5sums.txt; then echo "md5sum error!"; exi1; fi

# check that all fastqs are present
cmd="cd $SCRDIR"
run_cmd "$log"

grep $sample_id $samp2fq | cut -d"," -f2 | while read file; do
    if [ ! -f ${file} ]; then
        echo "$file missing!"
        exit 1
    else
        echo "$file is present: OK"
    fi
done

# reformat directory tree
cmd="mkdir -p ${SCRDIR}/Tarani_Run1248_scATAC/${sample_id}; mv ${SCRDIR}/Tarani_Run1248_scATAC/*.fastq.gz ${SCRDIR}/Tarani_Run1248_scATAC/${sample_id}"
run_cmd "$log"

cmd="mkdir -p ${SCRDIR}/Tarani_Run1247_scRNA/${sample_id}; mv ${SCRDIR}/Tarani_Run1247_scRNA/*.fastq.gz ${SCRDIR}/Tarani_Run1247_scRNA/${sample_id}"
run_cmd "$log"

# rename fastq files
cmd="cd ${SCRDIR}/Tarani_Run1247_scRNA/${sample_id}"
run_cmd "$log"

for f in *.fastq.gz; do 
    cmd="mv "$f" "${f//_scRNA/}""
    run_cmd "$log"
done

cmd="cd ${SCRDIR}/Tarani_Run1248_scATAC/${sample_id}"
run_cmd "$log"

for f in *.fastq.gz; do 
    cmd="mv "$f" "${f//_scATAC/}""
    run_cmd "$log"
done

# re-create libraries metadata
cmd="cd $SCRDIR; head -1 $library_metadata > library.csv"
run_cmd "$log"

# need to add absolute path
grep $sample_id $library_metadata | while read line; do
    cmd="echo "${SCRDIR}/${line}" >> library.csv"
    run_cmd "$log"
done

cat library.csv >> $log
cat library.csv >& 2

# generate count matrices
cmd="cd $SCRDIR; cellranger-arc count \
--id=${sample_id} \
--reference=${SCRDIR}/Mmul10 \
--libraries=${SCRDIR}/library.csv \
--create-bam=true \
--localcores=25"
run_cmd "$log"

# # tar gz
# cmd="tar -cvzf ${sample_id}.tar.gz ${sample_id}; md5sum ${sample_id}.tar.gz > ${sample_id}.md5sum.txt"
# run_cmd "$log"

# cmd="rclone copy local: 'dropbox:/14. Lab Members/jennifer/projects/utmb/nhp/processed/sample' --include ${sample_id}.tar.gz --include ${sample_id}.md5sum.txt --no-gzip-encoding --transfers 4 --multi-thread-streams 4"
# run_cmd "$log"

cmd="rsync -rtvL ${sample_id}/${sample_id}.mri.tgz ${sample_id}/outs ${outdir}/${sample_id}"
run_cmd "$log"

echo "Done!" >> $log
echo "Done!" >&2
