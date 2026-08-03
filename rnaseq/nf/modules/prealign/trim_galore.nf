nextflow.enable.dsl = 2

process TRIMGALORE {

    input:
    tuple val(sample_id), path(fq1), path(fq2)

    output:
    tuple val(sample_id), 
    path("trim_galore/*_val_1.fq.gz"), 
    path("trim_galore/*_val_2.fq.gz"), 
    path("trim_galore/*1*_trimming_report.txt"), 
    path("trim_galore/*2*_trimming_report.txt"), 
    emit: trimmed

    publishDir "results/01.trim_galore", mode: "copy"
    
    script:
    """
    trim_galore \
    --illumina \
    --cores 8 \
    --paired \
    --output_dir trim_galore \
    $fq1 $fq2
    """
}
