workdir=/dfs8/imarazzi_lab/share/pipelines/rna_seq
project_id=GSE253154_MTR4KO
run_id=run1

# test run (true,false)
test_pipeline=false

# nextflow parameters
params=${workdir}/${project_id}/${run_id}/work/run.yml

# output directory
outdir=${workdir}/${project_id}/${run_id}/sample

# download source
conda_environment=/dfs8/imarazzi_lab/share/jennifer/envs/rna-pipeline

# functions file
functions_file=/dfs6b/pub/jennipn6/helpers/functions.sh

# nextflow pipeline
nf_pipeline=/dfs6b/pub/jennipn6/pipelines/rna_seq/rnaseq-nf_v2

# reference location
reference_location=dropbox
reference_path="/14. Lab Members/jennifer/reference/personal/star_reference"
reference_prefix="GRCm39_M38.gencode.star_reference.tar.gz"

# fastq source
fastq_source=hpc3
fastq_dir=/dfs8/imarazzi_lab/share/pipelines/rna_seq/GSE253154_MTR4KO/run1/data