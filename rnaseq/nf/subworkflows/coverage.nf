nextflow.enable.dsl = 2

include { COVERAGE_PLU } from '../modules/coverage/coverage_plu'
include { COVERAGE_NEG } from '../modules/coverage/coverage_neg'

workflow COVERAGE {

    take:
    bam
    dirname

    main:
    COVERAGE_PLU(bam, dirname)
    COVERAGE_NEG(bam, dirname)

}