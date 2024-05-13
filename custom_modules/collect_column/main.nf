process COLLECT_COLUMN {
    input:
    tuple val(meta), path(abundance)
    tuple val(meta2), path(referenceGtf)
    val(column)
    val(header)
    val(sumOnDuplicateId)

    output:
    path("*.csv"), emit: csv

    container "quay.io/biocontainers/collect-columns:1.0.0--py_0"

    when:
    task.ext.when == null || task.ext.when

    script:
    def headers = "${header}" ? '-H' : ''
    def sumOnDuplicateIds = "${sumOnDuplicateId}" ? '-S' : ''
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def avail_mem = 3072
    if (!task.memory) {
        log.info '[Collect column] Available memory not known - defaulting to 3GB. Specify process memory requirements to change this.'
    } else {
        avail_mem = (task.memory.mega*0.8).intValue()
    }

    """
    collect-columns \\
    ${prefix}.csv \\
    $abundance \\
    ${column != 000 ? "-c $column" : ""} \\
    ${header} \\
    ${sumOnDuplicateIds}

    $args

    """
}
