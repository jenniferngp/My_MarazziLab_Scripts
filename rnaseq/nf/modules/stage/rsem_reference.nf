nextflow.enable.dsl = 2

process MAKE_RSEM_REF {

    input:
    path genome_fasta_file
    path gene_annotation_file

    output:
    path("rsem_reference")

    script:
    """
    mkdir rsem_reference
    rsem-prepare-reference \
    --gtf $gene_annotation_file \
    $genome_fasta_file \
    rsem_reference/rsem
    """
}