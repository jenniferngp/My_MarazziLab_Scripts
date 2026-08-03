nextflow.enable.dsl = 2

include { TRIMGALORE } from '../modules/prealign/trim_galore.nf'
include { FASTQC as FASTQC_TRIMMED } from '../modules/prealign/fastqc.nf'
include { FASTQC as FASTQC_PRETRIM } from '../modules/prealign/fastqc.nf'
include { SALMON_QUANT as SALMON_QUANT_PRETRIM } from '../modules/prealign/salmon_quant.nf'
include { SALMON_QUANT as SALMON_QUANT_TRIMMED } from '../modules/prealign/salmon_quant.nf'
include { SALMON_INDEX } from '../modules/prealign/salmon_index.nf'

workflow PREALIGN {

    take:
    reads_pattern
    transcriptome_fasta

    main:
    // 1. Trim reads
    read_ch = Channel.fromFilePairs(reads_pattern, checkIfExists: true).map { id,files -> tuple(id, files[0], files[1]) }
    trim_ch = TRIMGALORE(read_ch)

    // 2. Fastqc on trimmed reads
    trim_for_fastqc = trim_ch.map{ id, fq1, fq2, report1, report2 -> tuple(id, fq1, fq2) }
    trim_fastqc = FASTQC_TRIMMED("trimmed", trim_for_fastqc)

    // 3. Fastqc on pre-trimmed reads
    raw = FASTQC_PRETRIM("raw", read_ch)

    // 4. Gene quantification
    salmon_ref_ch = SALMON_INDEX(transcriptome_fasta)
    salmon_quant_raw_ch = SALMON_QUANT_PRETRIM("raw", read_ch, salmon_ref_ch)
    salmon_quant_trim_ch = SALMON_QUANT_TRIMMED("trimmed", trim_for_fastqc, salmon_ref_ch)

    emit:
    trim_fastqs = trim_for_fastqc
}