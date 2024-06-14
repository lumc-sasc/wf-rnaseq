//Processes are being included.
include { BEDTOOLS_MERGE as Bedtools_Merge} from "../modules/nf-core/bedtools/merge/main.nf"
include {BEDTOOLS_COMPLEMENT as Bedtools_Complement} from "../modules/nf-core/bedtools/complement/main.nf"
include {BEDTOOLS_INTERSECT as Bedtools_Intersect} from "../modules/nf-core/bedtools/intersect/main.nf"
include {BEDTOOLS_INTERSECT as Bedtools_IntersectX} from "../modules/nf-core/bedtools/intersect/main.nf"
include {BEDTOOLS_INTERSECT as Bedtools_IntersectY} from "../modules/nf-core/bedtools/intersect/main.nf"
include {SCATTERREGIONS as ScatterRegions} from "../modules/local/chunked_scatter/scatterregions/main.nf"



//Start of workflow
workflow Calculateregionswf {
    //Input of workflow are given.
    take:
    xNonParRegions
    yNonParRegions
    referenceFasta
    referenceFastaFai
    referenceFastaDict
    variantCallingRegions

    //Main part of workflow.
    main:

    //Checks whether xNonParRegions and yNonParRegions have been given.
    if (xNonParRegions.size() > 0 && yNonParRegions.size() > 0) {
        //Bedtools_Merge is executed, which combines both bed files.
        Bedtools_Merge([[id: "merge"], [xNonParRegions[1], yNonParRegions[1]]])

        //Executes bedtools complement, which returns all intervals of a genome that are not covered by at least one interval of the bed files.
        Bedtools_Complement(inputbed = Bedtools_Merge.out.bed, faidx = referenceFastaFai[1])

        if (variantCallingRegions.size() > 0) { 
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
            variantCallingRegions.size() > 0 ?
                Bedtools_Intersect.out.intersect :
            Bedtools_Complement.out.bed : 
        variantCallingRegions.size() > 0 ? variantCallingRegions : referenceFastaFai

        //Scatter regions so the regions can be used seperately in variantcalling.
        ScatterRegions(CalculatedAutosomalRegions)

    //Emit the output.
    emit:
    scatters = ScatterRegions.out.scatters
    xNonParRegions = variantCallingRegions.size() > 0 ? Bedtools_IntersectX.out.intersect : xNonParRegions
    yNonParRegions = variantCallingRegions.size() > 0 ? Bedtools_IntersectY.out.intersect : yNonParRegions

}
