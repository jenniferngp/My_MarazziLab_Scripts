nextflow.enable.dsl = 2

process BAM_QC_STATS {

    cpus 16

    input:
    tuple val(sample_id), path(bam), path(bai)
    val dirname
    path refflat
    path ribosomal_intervals_file
    path gene_annotation_bed
    
    output:
    tuple val(sample_id), path("*"), emit: qc_files

    publishDir "results/${dirname}", mode: "copy"

    script:
    """
    
    # Flagstat 
    samtools flagstat -@ 8 ${bam} > ${bam}.flagstat

    # Idxstats 
    samtools idxstats -@ 8 ${bam} > ${bam}.idxstats

    # Stats (corrected: your original duplicated idxstats)
    samtools stats -@ 8 ${bam} > ${bam}.stats

    # Insert size metrics
    picard -Xmx16g CollectInsertSizeMetrics \
    I=${bam} \
    O=${bam}.insert_size_metrics.txt \
    H=${bam}.insert_size_histogram.pdf \
    M=0.5

    # Picard CollectRnaSeqMetrics
    picard -Xmx16g CollectRnaSeqMetrics \
    I=${bam}  \
    O=${bam}.RNA_metrics.txt  \
    REF_FLAT=$refflat \
    STRAND=SECOND_READ_TRANSCRIPTION_STRAND \

    # Infer experiment
    infer_experiment.py \
    -r ${gene_annotation_bed} \
    -i ${bam} > ${bam}.inferred_experiment.txt
    """

}