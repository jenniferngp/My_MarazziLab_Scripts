
process COVERAGE_NEG {

    cpus 4

    input:
    tuple val(sample_id), path(bam), path(bai)
    val dirname

    output:
    path("${sample_id}.neg.bw")

    publishDir "results/${dirname}", mode:'copy'

    script:
    """
    bamCoverage \
    --outFileFormat bigwig \
    --skipNonCoveredRegions \
    --numberOfProcessors 4 \
    --binSize 10 \
    --normalizeUsing RPKM \
    --filterRNAstrand reverse \
    --bam $bam \
    --outFileName ${sample_id}.neg.bw

    """
}