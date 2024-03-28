include { BEDTOOLS_MERGE as Bedtools_Merge} from "../modules/bedtools/merge/main.nf"
include {BEDTOOLS_COMPLEMENT as Bedtools_Complement} from "../modules/bedtools/complement/main.nf"
include {BEDTOOLS_INTERSECT as Bedtools_Intersect} from "../modules/bedtools/intersect/main.nf"
include {BEDTOOLS_INTERSECT as Bedtools_IntersectX} from "../modules/bedtools/intersect/main.nf"
include {BEDTOOLS_INTERSECT as Bedtools_IntersectY} from "../modules/bedtools/intersect/main.nf"
include {SCATTERREGIONS as ScatterRegions} from "../custom_modules/chunked_scatter/scatterregions/main.nf"




workflow Calculateregionswf {
    take:
    xNonParRegions
    yNonParRegions
    referenceFasta
    referenceFastaFai
    referenceFastaDict
    variantCallingRegions

    main:
    if (xNonParRegions.size() > 0 && yNonParRegions.size() > 0) {
        Bedtools_Merge([[id: "merge"], [xNonParRegions[1], yNonParRegions[1]]])
        Bedtools_Complement(inputbed = Bedtools_Merge.out.bed, faidx = referenceFastaFai[1])

        if (variantCallingRegions != null) { 
            //convering regions to channels so they can be joined on the variantcallingregions
            variantCallingRegions_Channel = Channel.value([[id: "merge"],variantCallingRegions[1]])

            //converting path to channel where in the process variantcallingregions is added.
            XNonParRegionsChannel = Channel.value([[id:'X'], xNonParRegions[1]] << variantCallingRegions[1])
            YNonParRegionsChannel = Channel.value([[id:'Y'], yNonParRegions[1]] << variantCallingRegions[1])


            //intersect
            Bedtools_Intersect(regions = Bedtools_Complement.out.bed.join(variantCallingRegions_Channel), referenceFastaFai)
            XNonParRegionsChannel.view()
            Bedtools_IntersectX(regions = XNonParRegionsChannel, referenceFastaFai)
            Bedtools_IntersectY(regions = YNonParRegionsChannel, referenceFastaFai)
        }
    }
        //decided which regions will be used for scatter regions
        CalculatedAutosomalRegions = xNonParRegions.size() > 0 && yNonParRegions.size() > 0 ?
            variantCallingRegions != null ?
                Bedtools_Intersect.out.intersect :
            Bedtools_Complement.out.bed : 
        variantCallingRegions != null ? variantCallingRegions : referenceFastaFai

        ScatterRegions(CalculatedAutosomalRegions)


    emit:
    scatters = ScatterRegions.out.scatters
    xNonParRegions = variantCallingRegions != null ? Bedtools_IntersectX.out.intersect : xNonParRegions
    yNonParRegions = variantCallingRegions != null ? Bedtools_IntersectY.out.intersect : yNonParRegions

}
