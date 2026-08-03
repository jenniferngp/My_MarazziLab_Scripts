# 1. prepare bwa reference (only need to run once) - took ~5 min
config=/data/homezvol1/jennipn6/lab/pipelines/chip_seq/GSE167259/run1/work/02.config.sh
srun -c 12 --tmp=200G --constraint=fastscratch -p free -A imarazzi_lab --pty /bin/bash -i
source $config; module load miniconda3/24.9.2; source activate chip-pipeline
SCRDIR=`mktemp -d -p $TMPDIR`
cd $SCRDIR; mkdir -p $genome_prefix
rsync -rtvL $genome_fasta ${SCRDIR}/genome.fasta.gz && gunzip ${SCRDIR}/genome.fasta.gz
bwa index -p ${SCRDIR}/${genome_prefix}/${genome_prefix} genome.fasta
tar -cvzf ${genome_prefix}.tar.gz ${genome_prefix}
cmd="rclone copy local: 'dropbox:/14. Lab Members/jennifer/reference/personal/bwa' --include ${genome_prefix}.tar.gz --transfers 4 --no-gzip-encoding --multi-thread-streams 4 --progress"
echo $cmd; eval $cmd

# 2. create md5sum (need to do only once)
# need the following inputs: genebody bed, fasta, blacklist, fastqs of all samples

srun -c 12 --tmp=200G --constraint=fastscratch -p free -A imarazzi_lab --pty /bin/bash -i
SCRDIR=`mktemp -d -p $TMPDIR`
cd $SCRDIR; mkdir -p input
rsync -rtvL $genome_fasta input/genome.fasta.gz && gunzip input/genome.fasta.gz
rclone copy "dropbox:${reference_dropbox_path}" local:input --include ${genome_prefix}.tar.gz --transfers 4 --no-gzip-encoding --multi-thread-streams 4 --progress
wget -L $blacklist -O input/blacklist.bed.gz && gunzip input/blacklist.bed.gz; sed 's/^chr//' input/blacklist.bed > input/blacklist.nochr.bed; rm input/blacklist.bed; mv input/blacklist.nochr.bed input/blacklist.bed
for sampdir in ${fastqdir}/*; do if [ ! -d $sampdir ]; then cmd="rsync -r $sampdir input"; echo $cmd; eval $cmd; fi; done
rsync $genebody_bed ${SCRDIR}/input/genebody.bed
tree input

# input
# ├── blacklist.bed
# ├── genebody.bed
# ├── genome.fasta
# ├── GRCh38_v115.Ensembl.tar.gz
# ├── SRR13764806
# │   └── SRR13764806.fastq.gz
# ├── SRR13764807
# │   └── SRR13764807.fastq.gz
# ├── SRR13764808
# │   └── SRR13764808.fastq.gz
# ├── SRR13764809
# │   └── SRR13764809.fastq.gz
# ├── SRR13764810
# │   └── SRR13764810.fastq.gz
# ├── SRR13764811
# │   └── SRR13764811.fastq.gz
# ├── SRR13764812
# │   └── SRR13764812.fastq.gz
# ├── SRR13764813
# │   └── SRR13764813.fastq.gz
# ├── SRR13764814
# │   └── SRR13764814.fastq.gz
# ├── SRR13764815
# │   └── SRR13764815.fastq.gz
# ├── SRR13764816
# │   └── SRR13764816.fastq.gz
# └── SRR13764817
#     └── SRR13764817.fastq.gz

cd ${SCRDIR}/input; find -type f ! -name MD5_input.txt -exec md5sum '{}' \; > MD5_input.txt; rsync MD5_input.txt ${workdir}/work; cd $SCRDIR
