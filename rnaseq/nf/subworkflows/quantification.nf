nextflow.enable.dsl = 2

include { RSEM as RSEM_ALIGNED         } from '../modules/quant/rsem'
include { RSEM as RSEM_FILT            } from '../modules/quant/rsem'
include { TECOUNTS as TECOUNTS_ALIGNED } from '../modules/quant/tecounts'
include { TECOUNTS as TECOUNTS_FILT    } from '../modules/quant/tecounts'

workflow QUANTIFICATION {

    take:
    rsem_reference
    te_annotation_file
    tecounts_sif
    gene_annotation_file
    transcript_aligned
    transcript_filt
    genome_aligned
    genome_filt
    align_mode
    
    main:
    rsem_align_ch = RSEM_ALIGNED(rsem_reference, transcript_aligned, params.strandedness, params.paired, "07.rsem/calculateexpression/${align_mode}/aligned")
    rsem_filt_ch  = RSEM_FILT   (rsem_reference, transcript_filt   , params.strandedness, params.paired, "07.rsem/calculateexpression/${align_mode}/filt"   )

    te_align_ch = TECOUNTS_ALIGNED(genome_aligned, te_annotation_file, tecounts_sif, gene_annotation_file, "08.tecounts/${align_mode}/aligned")
    te_filt_ch  = TECOUNTS_FILT   (genome_filt   , te_annotation_file, tecounts_sif, gene_annotation_file, "08.tecounts/${align_mode}/filt"   )

}