nextflow.enable.dsl = 2

process STAR_ALIGN {

    cpus 12

    input:
    path star_reference
    tuple val(sample_id), path(fq1), path(fq2)
    val extra_star_args
    val dirname

    output:
    tuple val(sample_id), path("Aligned.genome.bam"), path("Aligned.genome.bam.bai"), emit: bam_genome
    tuple val(sample_id), path("Aligned.transcript.bam")                            , emit: bam_transcript
    tuple val(sample_id), path("Log.final.out")                                     , emit: logs
    
    publishDir "results/${dirname}", mode: "copy"

    script:
    """
    STAR \
    --runThreadN ${task.cpus} \
    --genomeDir $star_reference \
    --genomeLoad NoSharedMemory \
    --readFilesIn ${fq1} ${fq2} \
    --outSAMattributes All \
    --outSAMunmapped Within \
    --outSAMattrRGline ID:1 PL:PLATFORM PU:PROJECT LB:${sample_id} SM:${sample_id} \
    --outSAMtype BAM SortedByCoordinate \
    --outFileNamePrefix star_ \
    --readFilesCommand zcat \
    --quantMode TranscriptomeSAM \
    ${extra_star_args}
    
    # Index BAM file
    samtools index star_Aligned.sortedByCoord.out.bam

    # Rename
    mv star_Aligned.sortedByCoord.out.bam Aligned.genome.bam
    mv star_Aligned.toTranscriptome.out.bam Aligned.transcript.bam
    mv star_Aligned.sortedByCoord.out.bam.bai Aligned.genome.bam.bai
    mv star_Log.final.out Log.final.out
    """
}
