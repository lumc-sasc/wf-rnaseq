//Include modules
include { SAMTOOLS_SORT as SAMTOOLS_SORT_FOR_LONGGF }    from '../../modules/nf-core/samtools/sort/main'
include { LONGGF_RUN as LONGGF_RUN_VARIANT}              from './modules/main.nf'

workflow LONG_GF {
    take:
        bamfile
        referenceGTF
        referenceFasta

    main:
        SAMTOOLS_SORT_FOR_LONGGF(bamfile, referenceFasta)
        LONGGF_RUN_VARIANT(SAMTOOLS_SORT_FOR_LONGGF.out.bam, referenceGTF)

    emit:
        logFile = LONGGF_RUN_VARIANT.out
}

