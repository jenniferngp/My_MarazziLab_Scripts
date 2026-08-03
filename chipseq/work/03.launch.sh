# run chip-pipeline for inputs
project=GSE167259
run=run4
workdir=/dfs8/imarazzi_lab/share/pipelines/chip_seq/${project}/${run}
config=${workdir}/work/03.config.sh
run_pipeline=${workdir}/work/03.run_pipeline.sh
sampid=SRR13764817
input_sample="none"
ip_molecule="none"
mkdir -p ${workdir}/sample/${sampid}/logs
cmd="sbatch -p standard -o ${workdir}/sample/${sampid}/logs/chip-pipeline.stdout -e ${workdir}/sample/${sampid}/logs/chip-pipeline.stderr $run_pipeline $config $sampid $input_sample $ip_molecule"
echo $cmd; eval $cmd

# run chip-pipeline for ip'd samples
project=GSE167259
run=run4
workdir=/dfs8/imarazzi_lab/share/pipelines/chip_seq/${project}/${run}
config=${workdir}/work/03.config.sh
run_pipeline=${workdir}/work/03.run_pipeline.sh
samplelist=/data/homezvol1/jennipn6/lab/pipelines/chip_seq/${project}/${run}/work/00.samples_to_process.txt
input_sample=SRR13764817
JOB_ID=48014496
cat $samplelist | while read line; do
    line=($line)
    sampid=${line[0]}
    ip_molecule=${line[1]}
    if [[ "$sampid" != $input_sample ]]; then
        mkdir -p ${workdir}/sample/${sampid}/logs
        cmd="sbatch -p standard -o ${workdir}/sample/${sampid}/logs/chip-pipeline.stdout -e ${workdir}/sample/${sampid}/logs/chip-pipeline.stderr  $run_pipeline $config $sampid $input_sample $ip_molecule"
        echo $cmd; eval $cmd
    fi
done

