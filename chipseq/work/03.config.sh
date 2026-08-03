project_id=GSE167259
run_id=run4

# genome fasta
genome_fasta="/dfs8/imarazzi_lab/share/project/pch-release-115/in/hg38.genome.fasta.gz"

# gene annotations
gene_annotations=/dfs8/imarazzi_lab/share/project/pch-release-115/in/hg38.ensembl.transcriptome.annotation.gtf.gz

# prefix to name reference
genome_prefix="GRCh38_v115.Ensembl"

# as of jan 2026, this is the suggested website to get blacklist by nf-core
# web link to blacklist, needs to be gz
blacklist="https://raw.githubusercontent.com/Boyle-Lab/Blacklist/master/lists/hg38-blacklist.v2.bed.gz" 

# bed file of gene body coordinates (for assessing TSS enrichment)
# i'm only running genes on chr1 for time speedup
genebody_bed=/data/homezvol1/jennipn6/personal/reference/public/ensembl/GRCh38_v115/hg38-ensembl-v115-chr1.genebody.bed

# true, false to test pipeline using downsampled reads
test=false

# i usually save my bwa reference in my dropbox because of low storage space on the cluster
reference_dropbox_path="/14. Lab Members/jennifer/reference/personal/bwa" # need to be tar.gz and on dropbox

# library type, paired or single
libtype=single 

# parent fastq directory on hpc3, its subdirectories correspond to individual samples
fastqdir=/dfs8/imarazzi_lab/share/pipelines/chip_seq/${project_id}/${run_id}/data

# work pipeline directory
workdir=/data/homezvol1/jennipn6/lab/pipelines/chip_seq/${project_id}/${run_id}

# md5sums of inputs (reference and fastqs)
md5input_filename=${workdir}/work/MD5_input.txt

# output directory
outdir=${workdir}/sample

# pipeline script
pipeline=/data/homezvol1/jennipn6/lab/pipelines/chip_seq/${project_id}/${run_id}/work/03.chip_pipeline.sh

# yes,no upload to dropbox
upload_to_dropbox=yes
save_to_hpc3=yes

# dropbox output dir
dropbox_outdir="/16. Processed Data/ChIP/GSE167259/sample"

# read length
readlength=75

# full path to spp script
run_spp_script=/data/homezvol1/jennipn6/lab/jennifer/software/phantompeakqualtools/run_spp.R

# species for macs3 (ce = celegans, hs = homo sapiens, mm = mouse)
gs=hs

# effective genome size for deeptools
# https://deeptools.readthedocs.io/en/latest/content/feature/effectiveGenomeSize.html
effective_genome_size=2913022398

# narrow peaks q-value threshold
qthresh=0.05

# broad peaks merging q-value threshold (greater q = more permissive merging of narrow peaks to create broad peaks)
broad_qthresh=0.1