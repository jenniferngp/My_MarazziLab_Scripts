nextflow.enable.dsl = 2

include { STAGE_REF_FILE as STAGE_GENOME_FA } from '../modules/stage/stage_ref_file'
include { STAGE_REF_FILE as STAGE_GENE_GTF } from '../modules/stage/stage_ref_file'
include { STAGE_REF_FILE as STAGE_TE_GTF } from '../modules/stage/stage_ref_file'
include { STAGE_REF_FILE as STAGE_RIBO } from '../modules/stage/stage_ref_file'
include { STAGE_REF_FILE as STAGE_GENE_BED } from '../modules/stage/stage_ref_file'
include { MAKE_TRANSCRIPTOME_FASTA } from '../modules/stage/make_transcriptome_fa'
include { GET_STAR_INDEX } from '../modules/stage/get_star_index'
include { STAGE_REFFLAT } from '../modules/stage/refflat'
include { MAKE_RSEM_REF } from '../modules/stage/rsem_reference'

workflow STAGE_INPUTS {
    
    // 1. stage reference files
    genome_fa_ch = STAGE_GENOME_FA( Channel.value(params.genome_fasta_file)       , Channel.value("genome.fa")               )
    genes_gtf_ch = STAGE_GENE_GTF ( Channel.value(params.gene_annotation_file)    , Channel.value("gene_annotation.gtf")     )
    te_gtf_ch    = STAGE_TE_GTF   ( Channel.value(params.te_annotation_file)      , Channel.value("te_annotation.gtf")       )
    ribo_bed_ch  = STAGE_RIBO     ( Channel.value(params.ribosomal_intervals_file), Channel.value("ribosomal_intervals.bed") )
    bed12_ch     = STAGE_GENE_BED ( Channel.value(params.gene_annotation_bed)     , Channel.value("gene_annotation.bed12")   )
    reflat_ch    = STAGE_REFFLAT  ( Channel.value(params.gene_annotation_file))

    // 2. Make Salmon transcriptome fasta
    transcriptome_fa_ch = MAKE_TRANSCRIPTOME_FASTA(genome_fa_ch, genes_gtf_ch)

    // 3. Make star index (untar prebuilt or build from scratch)
    star_tar_ch = params.star_reference_tar
        ? Channel.fromPath("${params.workdir}/${params.star_reference_tar}", checkIfExists: true)
        : Channel.value(file("NO_FILE"))
    star_index_dir_ch = GET_STAR_INDEX(genome_fa_ch, genes_gtf_ch, star_tar_ch)

    // 4. Make RSEM reference
    rsem_ref_ch = MAKE_RSEM_REF(genome_fa_ch, genes_gtf_ch)

    emit:
    genome_fa        = genome_fa_ch
    genes_gtf        = genes_gtf_ch
    te_gtf           = te_gtf_ch
    ribo_bed         = ribo_bed_ch
    genes_gtf_bed    = bed12_ch
    transcriptome_fa = transcriptome_fa_ch
    star_index_dir   = star_index_dir_ch    
    refflat          = reflat_ch
    rsem_ref         = rsem_ref_ch
}
