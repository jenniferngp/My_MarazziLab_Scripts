nextflow.enable.dsl = 2

process SALMON_INDEX {

    cpus 4
    
    input:
    path transcriptome_fasta

    output:
    path "salmon_index"

    script:
    """
    salmon index --threads ${task.cpus} -t $transcriptome_fasta -i salmon_index
    """
}
