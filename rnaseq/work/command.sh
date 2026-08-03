# download fastqs
labdrive=/dfs8/imarazzi_lab/share
project_id=GSE253154_MTR4KO
run=run1
workdir=${labdrive}/pipelines/rna_seq/${project_id}/${run}/work
pipedir=${labdrive}/pipelines/rna_seq/${project_id}/${run}/sample
pipeline=${workdir}/download.sh
download_file=${workdir}/SraRunTable.csv
config=${workdir}/config.sh
cut -f1 -d"," $download_file  | tail -n +2 | while read sample_id; do
    # cmd="fasterq-dump $sample_id"
    # echo $cmd; eval $cmd
    logout=${pipedir}/${sample_id}/logs/download.stdout
    logerr=${pipedir}/${sample_id}/logs/download.stderr
    cmd="sbatch \
     -o $logout -e $logerr \
    $pipeline \
    $sample_id \
    $config"
    echo $cmd; eval $cmd
done

# run rnaseq pipeline
labdrive=/dfs8/imarazzi_lab/share
project_id=GSE253154_MTR4KO
run=run1
workdir=${labdrive}/pipelines/rna_seq/${project_id}/${run}/work
pipedir=${labdrive}/pipelines/rna_seq/${project_id}/${run}/sample
pipeline=${workdir}/run_pipeline.sh
download_file=${workdir}/SraRunTable.csv
config=${workdir}/config.sh
cut -f1 -d"," $download_file  | tail -n +2 | head -1 | while read sample_id; do
    if [ ! -d ${pipedir}/${sample_id}/multiqc_data ]; then
        logout=${pipedir}/${sample_id}/logs/rna-pipeline.stdout
        logerr=${pipedir}/${sample_id}/logs/rna-pipeline.stderr
        cmd="sbatch \
        -o $logout -e $logerr \
        $pipeline \
        $sample_id \
        $config"
        echo $cmd; eval $cmd
    else
        echo "${sample_id} already done!"
    fi
done

sh /dfs8/imarazzi_lab/share/pipelines/rna_seq/GSE253154_MTR4KO/run1/work/run_pipeline.sh 
sample_id=SRR27532308
config=/dfs8/imarazzi_lab/share/pipelines/rna_seq/GSE253154_MTR4KO/run1/work/config.sh

# combine bigwigs
labdrive=/dfs8/imarazzi_lab/share
project_id=GSE253154_MTR4KO
run=run1
workdir=${labdrive}/pipelines/rna_seq/${project_id}/${run}/work
pipedir=${labdrive}/pipelines/rna_seq/${project_id}/${run}/sample
pipeline=${workdir}/run_pipeline.sh
download_file=${workdir}/SraRunTable.csv
config=${workdir}/config.sh
tail -n +2 $download_file | while IFS=',' read -r -a fields; do
    sample_id="${fields[0]}"
    genotype="${fields[23]}"    # 0-indexed, column 17
    cmd="ln -s ${pipedir}/${sample_id}/09.deeptools/bamcoverage/genemode/filt/${sample_id}.plu.bw  ${genotype}_${sample_id}.plu.bw; ln -s ${pipedir}/${sample_id}/09.deeptools/bamcoverage/genemode/filt/${sample_id}.neg.bw ${genotype}_${sample_id}.neg.bw"
    echo $cmd; eval $cmd
    #echo "$sample_id $genotype"
done

