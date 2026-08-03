nextflow.enable.dsl = 2

process RSEM {

    cpus 8

    input:
    path rsem_reference
    tuple val(sample_id), path(transcript_bam)
    val strandedness
    val paired
    val dirname
    
    output:
    path("rsem.*")

    publishDir "results/${dirname}", mode:"copy"

    script:
    """
    if [[ $strandedness == "forward" ]]; then
        strandedness='--strandedness forward'
    elif [[ $strandedness == "reverse" ]]; then
        strandedness='--strandedness reverse'
    elif [[ $strandedness == "none" ]]; then
        strandedness='--strandedness none'
    fi

    if [[ $paired == "paired" ]]; then
        paired_end='--paired-end'
    else
        paired_end=''
    fi
        
    rsem-calculate-expression \\
    --no-bam-output \\
    --alignments \\
    -estimate-rspd \\
    --num-threads ${task.cpus} \\
    --seed 3272015 \\
    \${strandedness} \\
    \${paired_end} \\
    ${transcript_bam} \\
    ${rsem_reference}/rsem \\
    rsem 
    
    """
}