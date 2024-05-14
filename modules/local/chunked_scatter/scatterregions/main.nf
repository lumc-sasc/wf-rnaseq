process SCATTERREGIONS {
    input:
    tuple val(meta), path(input_file)

    output:
    path "*.bed", emit: scatters

    container "quay.io/biocontainers/chunked-scatter:1.0.0--py_0"

    
    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    scatter-regions \\
    $input_file \\
    $args
    """
}