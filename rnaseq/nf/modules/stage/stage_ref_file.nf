nextflow.enable.dsl = 2

process STAGE_REF_FILE {
    cpus 1
    
    input:
    val src
    val outname
    
    output:
    path outname
    
    script:
    """
    if [[ ${src} == *.gz ]]; then
        rsync ${src} ${outname}.gz
        gunzip -c ${outname}.gz > ${outname}
    else
        rsync ${src} ${outname}
    fi
    """
}