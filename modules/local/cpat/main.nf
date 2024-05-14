process CPAT {
    input:
    path(gene)
    path(CpatHex)
    path(CpatLogitModel)
    tuple val(meta2), path(referenceFasta)
    tuple val(meta3), path(referenceFastaFai)

    output:
    path("*.fa"), emit: orfSeqs, optional: true
    path("*prob.tsv"), emit: orfProb, optional: true
    path("*best.tsv"), emit: orfProbBest, optional: true
    path("*.txt"), emit: noOrf, optional: true
    path("*.r"), emit: rScript, optional: true

    container "quay.io/biocontainers/cpat:3.0.4--py39hcbe4a3b_0"

    script:
    def args = task.ext.args ?: ''
    """
    cpat.py \\
    -g $gene \\
    -x $CpatHex \\
    -d $CpatLogitModel \\
    -r $referenceFasta\\
    -o .
    $args
    """


    
}