include { BEDTOOLS_MERGE as Bedtools_Merge} from "../modules/bedtools/merge/main.nf"
include {BEDTOOLS_COMPLEMENT as Bedtools_Complement} from "../modules/bedtools/complement/main.nf"
include {BEDTOOLS_INTERSECT as Bedtools_Intersect} from "../modules/bedtools/intersect/main.nf"
include {BEDTOOLS_INTERSECT as Bedtools_IntersectX} from "../modules/bedtools/intersect/main.nf"
include {BEDTOOLS_INTERSECT as Bedtools_IntersectY} from "../modules/bedtools/intersect/main.nf"
include {SCATTERREGIONS as ScatterRegions} from "../custom_modules/chunked_scatter/scatterregions/main.nf"




workflow Calculateregionswf {
    take:
    XNonParRegions
    YNonParRegions
    referenceFasta
    referenceFastaFai
    referenceFastaDict
    variantCallingRegions

    main:
    if (XNonParRegions != null && YNonParRegions != null) {
        Bedtools_Merge([[id: "merge"], [XNonParRegions, YNonParRegions]])
        Bedtools_Complement(inputbed = Bedtools_Merge.out.bed, faidx = referenceFastaFai[1])

        if (variantCallingRegions != null) { 
            //convering regions to channels so they can be joined on the variantcallingregions
            variantCallingRegions_Channel = Channel.value([[id: "merge"],variantCallingRegions[1]])

            //converting path to channel where in the process variantcallingregions is added.
            XNonParRegionsChannel = Channel.value([[id:'X'], XNonParRegions] << variantCallingRegions[1])
            YNonParRegionsChannel = Channel.value([[id:'Y'], YNonParRegions] << variantCallingRegions[1])


            //intersect
            Bedtools_Intersect(regions = Bedtools_Complement.out.bed.join(variantCallingRegions_Channel), referenceFastaFai)
            Bedtools_IntersectX(regions = XNonParRegionsChannel, referenceFastaFai)
            Bedtools_IntersectY(regions = YNonParRegionsChannel, referenceFastaFai)
        }
    }
        //decided which regions will be used for scatter regions
        CalculatedAutosomalRegions = XNonParRegions != null && YNonParRegions != null ?
            variantCallingRegions != null ?
                Bedtools_Intersect.out.intersect :
            Bedtools_Complement.out.bed : 
        variantCallingRegions != null ? variantCallingRegions : referenceFastaFai

        ScatterRegions(CalculatedAutosomalRegions)


    emit:
    scatters = ScatterRegions.out.scatters
    XNonParRegions = variantCallingRegions != null ? Bedtools_IntersectX.out.intersect : XNonParRegions
    YNonParRegions = variantCallingRegions != null ? Bedtools_IntersectY.out.intersect : YNonParRegions

}
