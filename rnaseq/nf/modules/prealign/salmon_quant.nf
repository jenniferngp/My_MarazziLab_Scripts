nextflow.enable.dsl = 2


process SALMON_QUANT {

    cpus 4

    input:
    val(prefix)
    tuple val(sample_id), path(fq1), path(fq2)
    path salmon_index

    output:
    path("salmon_quant")

    publishDir "results/03.salmon/${prefix}", mode: "copy"

    script:
    """
    salmon quant --libType=A -i $salmon_index -1 $fq1 -2 $fq2 -o salmon_quant
    """

}