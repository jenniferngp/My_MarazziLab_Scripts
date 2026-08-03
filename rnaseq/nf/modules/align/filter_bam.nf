nextflow.enable.dsl = 2

process FILTER_BAM {

    cpus 4

    input:
    tuple val(sample_id), path(genome_mdup_bam), path(genome_mdup_bai)
    tuple val(sample_id), path(transcript_bam)
    val dirname
    val filter_bam_args

    output:
    tuple val(sample_id), path("Aligned.genome.mdup.filt.bam"), path("Aligned.genome.mdup.filt.bam.bai"), emit: bam_genome
    tuple val(sample_id), path("Aligned.transcript.filt.bam")                                           , emit: bam_transcript

    publishDir "results/${dirname}", mode: "copy"
    
    script:
    """
    # Filter bam
    samtools view ${filter_bam_args} -o Aligned.genome.mdup.filt.bam ${genome_mdup_bam}
    samtools view ${filter_bam_args} -o Aligned.transcript.filt.bam ${transcript_bam}

    # Index Bam
    samtools index Aligned.genome.mdup.filt.bam
    """

}