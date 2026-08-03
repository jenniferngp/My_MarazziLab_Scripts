nextflow.enable.dsl = 2

process MARKDUP {

    cpus 4

    input:
    tuple val(sample_id), path(genome_bam), path(genome_bai)
    val dirname

    output:
    tuple val(sample_id), path("Aligned.genome.mdup.bam"), path("Aligned.genome.mdup.bam.bai"), emit: bam_genome

    publishDir "results/${dirname}", mode: "copy"
    
    script:
    """
    # Add ReadGroups (needed for picard MarkDuplicates)
    picard AddOrReplaceReadGroups \
    I=$genome_bam \
    O=rg.bam \
    RGID=4 \
    RGLB=$sample_id \
    RGPL=ILLUMINA \
    RGPU=unit1 \
    RGSM=$sample_id

    # Mark duplicates
    picard MarkDuplicates \
    I=rg.bam \
    O=Aligned.genome.mdup.bam \
    M=picard_marked_dup_metrics.txt

    # Index BAM
    samtools index Aligned.genome.mdup.bam 

    """

}