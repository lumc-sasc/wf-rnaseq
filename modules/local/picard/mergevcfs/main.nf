process PICARD_MERGEVCFS {
    input:
    tuple val(meta), path(vcfs), path(index)

    output:
    tuple val(meta), path("${prefix}.vcf"), path("${prefix}.tbi"), emit: vcf

    when:
        task.ext.when == null || task.ext.when

    script:
    
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def avail_mem = 3072
    if (!task.memory) {
        log.info '[Picard MergeVcfs] Available memory not known - defaulting to 3GB. Specify process memory requirements to change this.'
    } else {
        avail_mem = (task.memory.mega*0.8).intValue()
    }

    """
    picard -Xmx~{javaXmxMb}M -XX:ParallelGCThreads=1 \\
    MergeVcfs \\
    ${vcfs.collect { "--INPUT " + it }.join(" ")}\\
    """

}