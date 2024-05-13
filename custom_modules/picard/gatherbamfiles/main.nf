process PICARD_GATHERBAMFILES {
    input:
    tuple val(meta), path(bam)
    path bai

    output:
    tuple val(meta), path("${prefix}.bam"), emit: bam
    path "*.bai", emit: bai
    path "*.md5", optional: true

    when:
        task.ext.when == null || task.ext.when

    script:
    
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def avail_mem = 3072
    if (!task.memory) {
        log.info '[Picard GatherBamFiles] Available memory not known - defaulting to 3GB. Specify process memory requirements to change this.'
    } else {
        avail_mem = (task.memory.mega*0.8).intValue()
    }

    """
    picard -Xmx~{javaXmxMb}M -XX:ParallelGCThreads=1 \\
    GatherBamFiles \\
    ${bam.collect { "--INPUT " + it }.join(" ")}\\
    --CREATE_INDEX true \\
    """

}