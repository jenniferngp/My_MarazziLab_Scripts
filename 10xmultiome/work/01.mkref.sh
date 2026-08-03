# 1. each transcript should have at least one exon
# 2. "transcript" should precede "exon" entries
export PATH=/dfs6b/pub/jennipn6/software/cellranger-arc-2.1.0:$PATH

cellranger-arc mkref --nthreads=14 --config=/dfs8/imarazzi_lab/share/jennifer/multiome/run2/processed/work/00.config.sh

tree

# ├── Mmul_10
# │   ├── fasta
# │   │   ├── genome.fa
# │   │   ├── genome.fa.amb
# │   │   ├── genome.fa.ann
# │   │   ├── genome.fa.bwt
# │   │   ├── genome.fa.fai
# │   │   ├── genome.fa.pac
# │   │   └── genome.fa.sa
# │   ├── genes
# │   │   └── genes.gtf.gz
# │   ├── reference.json
# │   ├── regions
# │   │   ├── motifs.pfm
# │   │   ├── transcripts.bed
# │   │   └── tss.bed
# │   └── star
# │       ├── chrLength.txt
# │       ├── chrNameLength.txt
# │       ├── chrName.txt
# │       ├── chrStart.txt
# │       ├── exonGeTrInfo.tab
# │       ├── exonInfo.tab
# │       ├── geneInfo.tab
# │       ├── Genome
# │       ├── genomeParameters.txt
# │       ├── SA
# │       ├── SAindex
# │       ├── sjdbInfo.txt
# │       ├── sjdbList.fromGTF.out.tab
# │       ├── sjdbList.out.tab
# │       └── transcriptInfo.tab
# ├── Mmul_10.fixed.gtf
# └── Mmul_10.fixed.sorted.gtf

# 5 directories, 29 files

# compress
cmd="tar -cvzf Mmul10.tar.gz Mmul10"
echo $cmd; eval $cmd

cmd="rclone copy local:Mmul10.tar.gz 'dropbox:/14. Lab Members/jennifer/reference/personal/cellranger_reference' --no-gzip-encoding --transfers 4 --multi-thread-streams 4 --progress"
echo $cmd; eval $cmd
