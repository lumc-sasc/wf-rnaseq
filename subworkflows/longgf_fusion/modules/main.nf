process LONGGF_RUN {
    tag "$meta.id"
    
    container  "https://depot.galaxyproject.org/singularity/longgf:0.1.2--h84372a0_6"
    
    input:
        tuple val(meta), path(sortedBamFile)
        tuple val(meta2), path(referenceGtf)
    
    output:
       tuple val(meta), path("${meta.id}.LongGF.log")
    
    script: 
        """
        LongGF $sortedBamFile $referenceGtf 100 30 100 1 0  > ${meta.id}.LongGF.log
        """
}