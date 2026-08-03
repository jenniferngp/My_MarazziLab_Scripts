run_id=run2
workdir=/dfs8/imarazzi_lab/share/jennifer/utmb/nhp/multiome/${run_id}/processed/work
samples=${workdir}/02.sample2fastqs.csv
outdir=/dfs8/imarazzi_lab/share/jennifer/utmb/nhp/multiome/${run_id}/processed/sample
library_metadata=/dfs8/imarazzi_lab/share/jennifer/utmb/nhp/multiome/${run_id}/processed/work/02.libraries.csv
samp2fq=/dfs8/imarazzi_lab/share/jennifer/utmb/nhp/multiome/${run_id}/processed/work/02.sample2fastqs.csv
pipeline=${workdir}/03.count.sh
tail -n +2 $samples | cut -f1 -d"," | sort -u | grep "UG1722_Day6_EBOV_Liver3" | while read sample_id; do
    if [ -d ${outdir}/${sample_id}/outs ]; then echo "$sample_id Done"; continue; fi
    if [ $sample_id == "UG1695_Day6_EBOV_Liver5" ]; then continue; fi
    if [ $sample_id == "FR1631_Day6_EBOV_Liver4" ]; then continue; fi
    mkdir -p ${outdir}/${sample_id}/logs
    cmd="sbatch --nodelist=hpc3-23-13,hpc3-20-16,hpc3-20-24 -o ${outdir}/${sample_id}/logs/count.stdout -e ${outdir}/${sample_id}/logs/count.stderr $pipeline $outdir $sample_id $library_metadata $samp2fq"
    echo $cmd; eval $cmd
done

cd /tmp/jennipn6/53330145/tmp.B4KKVG9itw; cellranger-arc count --id=EC755_Day6_mock_Liver6 --reference=/tmp/jennipn6/53330145/tmp.B4KKVG9itw/Mmul10_ZEBOV --libraries=/tmp/jennipn6/53330145/tmp.B4KKVG9itw/library.csv --create-bam=true --localcores=24 --localmem=96

#sample_id=UG1695_Day6_EBOV_Liver5
#cmd="sbatch -o ${outdir}/${sample_id}/logs/count.stdout -e ${outdir}/${sample_id}/logs/count.stderr $pipeline $outdir $sample_id $library_metadata $samp2fq"
#echo $cmd
