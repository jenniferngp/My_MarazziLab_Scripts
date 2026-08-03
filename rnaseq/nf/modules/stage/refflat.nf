nextflow.enable.dsl = 2

process STAGE_REFFLAT {

    input:
    path gene_annotation_file

    output:
    path("ref_flat.txt")

    script:
    """
    gtfToGenePred \
    -genePredExt \
    -geneNameAsName2 \
    -ignoreGroupsWithoutExons \
    ${gene_annotation_file} \
    /dev/stdout | \
    awk 'BEGIN { OFS="\t"} {print \$12, \$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10}' \
    > ref_flat.txt
    """
}
    