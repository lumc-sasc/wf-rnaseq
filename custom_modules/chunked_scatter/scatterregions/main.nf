process SCATTERREGIONS {
    input:
    tuple val(meta), path(input_file)

    output:
    path "*.bed", emit: scatters

    container "quay.io/biocontainers/chunked-scatter:1.0.0--py_0"

    
    script:
    """
    scatter-regions \\
    $input_file

    """
}