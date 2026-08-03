nextflow.enable.dsl = 2

include { STAR_ALIGN } from '../modules/align/star_align.nf'
include { MARKDUP } from '../modules/align/markdup.nf'
include { FILTER_BAM } from '../modules/align/filter_bam.nf'

workflow STAR_ALIGN_CHAIN {

    take:
    star_reference
    trim_fastqs
    star_extra_args
    filter_bam_args
    dirname

    main:

    // 1. STAR align
    aligned_ch = STAR_ALIGN(star_reference, trim_fastqs, star_extra_args, dirname)

    // 2. Mark dup
    mdup_ch = MARKDUP(aligned_ch.bam_genome, dirname)

    // 3. Filter prop-paired
    filt_ch = FILTER_BAM(mdup_ch.bam_genome, aligned_ch.bam_transcript, dirname, filter_bam_args)

    emit:
    transcript_aligned = aligned_ch.bam_transcript
    genome_aligned     = mdup_ch.bam_genome
    genome_filt        = filt_ch.bam_genome
    transcript_filt    = filt_ch.bam_transcript
}