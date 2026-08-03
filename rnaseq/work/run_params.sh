# set project and run_id
project_id=GSE253154_MTR4KO
run_id=run1
labdrive=/dfs8/imarazzi_lab/share

# fastq dir in lab drive
fastq_dir=${labdrive}/pipelines/rna_seq/${project_id}/${run_id}/data

# outdir in lab drive
outdir=${labdrive}/pipelines/rna_seq/${project_id}/${run_id}/sample

# True/False if test run
test_run=True

# nextflow parameters
nfparams=${labdrive}/pipelines/rna_seq/${project_id}/${run_id}/work/run.yml

# where to download
download_source=geo

# SRA metadata
srameta=${labdrive}/pipelines/rna_seq/${project_id}/${run_id}/work/SraRunTable.csv

