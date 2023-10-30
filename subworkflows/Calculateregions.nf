include { BEDTOOLS_MERGE as Bedtools_Merge} from "../modules/bedtools/merge/main.nf"

process Merge {
    input:
    path XNonParRegions
    path YNonParRegions

    output:
    tuple val(meta), path("NonParRegions.bed"), emit: regions

    script:
    meta = [id: "NonParRegions"]
    """
    cat ${XNonParRegions} ${YNonParRegions} > "NonParRegions.bed"
    """
}

workflow Calculateregionswf {
    take:
    bam
    XNonParRegions
    YNonParRegions

    main:
    if (XNonParRegions != null && YNonParRegions != null) {
        Merge(XNonParRegions,YNonParRegions)
        Bedtools_Merge(Merge.out.regions)
    }
}
