nextflow.enable.dsl = 2

process TECOUNTS {

    input:
    tuple val(sample_id), path(bam), path(bai)
    path te_annotation_file
    path tecounts_sif
    path gene_annotation_file
    val dirname
    
    output:
    path "tecounts.cntTable"
    
    publishDir "results/${dirname}", mode: 'copy'
    
    script:
    """
    singularity exec \
    $tecounts_sif TEcount \
    --stranded reverse \
    --format BAM \
    --mode multi \
    --sortByPos \
    -b ${bam} \
    --project tecounts \
    --GTF $gene_annotation_file \
    --TE $te_annotation_file
    """
}