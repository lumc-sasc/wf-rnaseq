process PICARD_GATHERBAMFILES {
    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("*.bam"), emit: bam
    path "*.bai", emit: bai, optional: true
    path "*.md5", optional: true


    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/picard:3.1.1--hdfd78af_0' :
        'biocontainers/picard:3.1.1--hdfd78af_0' }"

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
    picard -Xmx${avail_mem}M \\
    GatherBamFiles \\
    $args \\
    --OUTPUT ${prefix}.bam \\
    ${bam.collect { "--INPUT " + it }.join(" ")}
    """

}