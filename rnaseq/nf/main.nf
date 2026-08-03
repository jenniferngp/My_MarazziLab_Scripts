nextflow.enable.dsl = 2

include { STAGE_INPUTS                              } from './subworkflows/stage_inputs.nf'
include { PREALIGN                                  } from './subworkflows/prealign_processing.nf'
include { STAR_ALIGN_CHAIN as STAR_GENE_ALIGN_CHAIN } from './subworkflows/star_align_chain.nf'
include { STAR_ALIGN_CHAIN as STAR_TE_ALIGN_CHAIN   } from './subworkflows/star_align_chain.nf'
include { BAM_QC_STATS as GENE_BAM_QC_STATS         } from './modules/qc_bam/bam_qc_stats'
include { BAM_QC_STATS as GENE_FILT_BAM_QC_STATS    } from './modules/qc_bam/bam_qc_stats'
include { BAM_QC_STATS as TE_BAM_QC_STATS           } from './modules/qc_bam/bam_qc_stats'
include { BAM_QC_STATS as TE_FILT_BAM_QC_STATS      } from './modules/qc_bam/bam_qc_stats'
include { RSEM as RSEM_GENE_ALIGNED                 } from './modules/quant/rsem'
include { RSEM as RSEM_TE_ALIGNED                   } from './modules/quant/rsem'
include { RSEM as RSEM_GENE_FILT                    } from './modules/quant/rsem'
include { RSEM as RSEM_TE_FILT                      } from './modules/quant/rsem'
include { TECOUNTS as TECOUNTS_GENE_MDUP            } from './modules/quant/tecounts'
include { TECOUNTS as TECOUNTS_GENE_FILT            } from './modules/quant/tecounts'
include { TECOUNTS as TECOUNTS_TE_MDUP              } from './modules/quant/tecounts'
include { TECOUNTS as TECOUNTS_TE_FILT              } from './modules/quant/tecounts'
include { COVERAGE as COVERAGE_GENEMODE_ALIGNED     } from './subworkflows/coverage'
include { COVERAGE as COVERAGE_GENEMODE_FILT        } from './subworkflows/coverage'
include { COVERAGE as COVERAGE_TEMODE_ALIGNED       } from './subworkflows/coverage'
include { COVERAGE as COVERAGE_TEMODE_FILT          } from './subworkflows/coverage'
include { QUANTIFICATION as QUANT_GENEMODE          } from './subworkflows/quantification'
include { QUANTIFICATION as QUANT_TEMODE            } from './subworkflows/quantification'

params.reads = "${params.workdir}/${params.reads}"

log.info """\
    R N A S E Q   P I P E L I N E
    =============================
    Author(s)          : Jennifer P. Nguyen
    projectDir         : ${projectDir}
    workdir            : ${params.workdir}
    genome_fasta       : ${params.genome_fasta_file}
    gene_annotation    : ${params.gene_annotation_file}
    te_annotation      : ${params.te_annotation_file}
    tecounts_sif       : ${params.tecounts_sif_file}
    ribosomal_intervals: ${params.ribosomal_intervals_file}
    star_reference     : ${params.star_reference_tar}
    read pattern       : ${params.reads}
    star_gene_args     : ${params.star_gene_extra_args}
    star_te_args       : ${params.star_te_extra_args}
    strandedness       : ${params.strandedness}
    paired             : ${params.paired}
    filter_bam_args    : ${params.filter_bam_args}
""".stripIndent()

workflow {

    // --------------------
    // 1. Stage input files
    // --------------------

    staged = STAGE_INPUTS()


    // --------------------
    // 2. Pre-alignment processing (trim, fastqc, salmon)
    // --------------------

    pre = PREALIGN(params.reads, staged.transcriptome_fa)


    // --------------------
    // 3. Align (star, markdup, prop paired)
    // --------------------

    align_gene_mode = STAR_GENE_ALIGN_CHAIN(staged.star_index_dir, pre.trim_fastqs, params.star_gene_extra_args, params.filter_bam_args, "04.star/genemode")
    align_te_mode   = STAR_TE_ALIGN_CHAIN  (staged.star_index_dir, pre.trim_fastqs, params.star_te_extra_args  , params.filter_bam_args, "04.star/temode"  )


    // --------------------
    // 4. BAM QC stats
    // --------------------

    GENE_BAM_QC_STATS     (align_gene_mode.genome_aligned, "05.bam_qc/genemode", staged.refflat, staged.ribo_bed, staged.genes_gtf_bed)
    GENE_FILT_BAM_QC_STATS(align_gene_mode.genome_filt   , "05.bam_qc/genemode", staged.refflat, staged.ribo_bed, staged.genes_gtf_bed)
    TE_BAM_QC_STATS       (align_te_mode.genome_aligned  , "05.bam_qc/temode"  , staged.refflat, staged.ribo_bed, staged.genes_gtf_bed)
    TE_FILT_BAM_QC_STATS  (align_te_mode.genome_filt     , "05.bam_qc/temode"  , staged.refflat, staged.ribo_bed, staged.genes_gtf_bed)


    // --------------------
    // 5. Quantification
    // --------------------

    QUANT_GENEMODE(staged.rsem_ref, staged.te_gtf, params.tecounts_sif_file, staged.genes_gtf, align_gene_mode.transcript_aligned, align_gene_mode.transcript_filt, align_gene_mode.genome_aligned, align_gene_mode.genome_filt, "genemode")
    QUANT_TEMODE(staged.rsem_ref, staged.te_gtf, params.tecounts_sif_file, staged.genes_gtf, align_te_mode.transcript_aligned, align_te_mode.transcript_filt, align_te_mode.genome_aligned, align_te_mode.genome_filt, "temode")

    // --------------------
    // 6. Coverage
    // --------------------

    COVERAGE_GENEMODE_ALIGNED(align_gene_mode.genome_aligned, "09.deeptools/bamcoverage/genemode/aligned" )
    COVERAGE_TEMODE_ALIGNED  (align_te_mode.genome_aligned  , "09.deeptools/bamcoverage/temode/aligned"   )
    COVERAGE_GENEMODE_FILT   (align_gene_mode.genome_filt   , "09.deeptools/bamcoverage/genemode/filt"    )
    COVERAGE_TEMODE_FILT     (align_te_mode.genome_filt     , "09.deeptools/bamcoverage/temode/filt"      )
    

}