nextflow.enable.dsl = 2

process FASTQC {

    cpus 2

    input: 
    val(prefix)
    tuple val(sample_id), path(fq1), path(fq2)

    output:
    path("*_fastqc.zip")
    path("*_fastqc.html")

    publishDir "results/02.fastqc/${prefix}", mode: "copy"

    script:
    """
    fastqc ${fq1} ${fq2}
    """
}