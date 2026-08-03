nextflow.enable.dsl = 2

process MAKE_TRANSCRIPTOME_FASTA {

    cpus 2

    input: 
    path genome_fa
    path gene_annotation_gtf

    output:
    path("transcriptome.fa")

    script:
    """
    set -euo pipefail
    samtools faidx $genome_fa
    gffread -w transcriptome.fa -g $genome_fa $gene_annotation_gtf
    """
}

