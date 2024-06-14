process CONVERTTEXTTOCSV {
    input:
    tuple val(meta), path(text)

    output:
    tuple val(meta), path("*.csv"), emit: csv

    script:
    """
    sed 's/ /,/g' $text > out.csv
    """
}