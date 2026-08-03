nextflow.enable.dsl = 2

process GET_STAR_INDEX {
    cpus 4

    input:
    path genome_fa
    path gene_annotation_gtf
    path star_reference_tar  // staged into work dir via channel

    output:
    path "star_reference"

    script:
    if (star_reference_tar.name != 'NO_FILE')
        """
        mkdir -p star_reference
        tar -xzf star_reference.tar.gz -C star_reference --strip-components 1
        """
    else
        """
        mkdir -p star_reference
        STAR \
            --runMode genomeGenerate \
            --genomeDir star_reference \
            --genomeFastaFiles ${genome_fa} \
            --sjdbGTFfile ${gene_annotation_gtf} \
            --runThreadN ${task.cpus}
        """
}