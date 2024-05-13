//Processes are being included.
include {GATK4_HAPLOTYPECALLER as Gatk4_Haplotypecaller} from "../../modules/nf-core/gatk4/haplotypecaller/main.nf"
include {GATK4_HAPLOTYPECALLER as Gatk4_HaplotypecallerX} from "../../modules/nf-core/gatk4/haplotypecaller/main.nf"
include {GATK4_HAPLOTYPECALLER as Gatk4_HaplotypecallerY} from "../../modules/nf-core/gatk4/haplotypecaller/main.nf"
include {GATK4_COMBINEGVCFS as Gatk4_Combinegvcfs} from "../../modules/nf-core/gatk4/combinegvcfs/main.nf"
include {PICARD_MERGEVCFS as Picard_Mergevcfs} from "../../modules/local/picard/mergevcfs/main.nf"
include {BCFTOOLS_STATS as Bcftools_Stats} from "../../modules/nf-core/bcftools/stats/main.nf"



//files and/or variables used for the subworkflow
    Dragstr_model = file("./inputfiles/${params.Dragstr_model}").exists() ? Channel.value(file("./inputfiles/${params.Dragstr_model}")) : Channel.value([]).toList()

    Bcfstats_regions = file("./inputfiles/${params.Bcfstats_regions}").exists() ?
        Channel.value([[id: "regions"],[file("./inputfiles/${params.Bcfstats_regions}")]]) :
        Channel.value([[id: "regions"],[]])

    Bcfstats_targets = file("./inputfiles/${params.Bcfstats_targets}").exists() ?
        Channel.value([[id: "targets"],[file("./inputfiles/${params.Bcfstats_targets}")]]) :
        Channel.value([[id: "targets"],[]])

    Bcfstats_samples = file("./inputfiles/${params.Bcfstats_samples}").exists() ?
        Channel.value([[id: "samples"],[file("./inputfiles/${params.Bcfstats_samples}")]]) :
        Channel.value([[id: "samples"],[]])
    
    Bcfstats_exons = file("./inputfiles/${params.Bcfstats_exons}").exists() ?
        Channel.value([[id: "exons"],[file("./inputfiles/${params.Bcfstats_exons}")]]) :
        Channel.value([[id: "exons"],[]])

//Start of workflow
workflow SingleSampleCallingwf {
    //Input of workflow are given.
    take:
    bam
    bai
    referenceFasta
    referenceFastaFai
    referenceFastaDict
    dbsnpVCF
    dbsnpVCFIndex
    xNonParRegions
    yNonParRegions
    autosomalregions

    //Main part of workflow.
    main:
    //Haplotypecaller
    autosomalregions.view()
    Dragstr_model.view()
    Gatk4_Haplotypecaller(bam.join(bai).combine(autosomalregions.flatten()).combine(Dragstr_model),
    referenceFasta, referenceFastaFai, referenceFastaDict, dbsnpVCF, dbsnpVCFIndex)

    //Haplotypecaller if Xnonparregions and YnonparsRegions are given
    if (xNonParRegions != [] && yNonParRegions != []) {
        //XnonParRegions converted to Channel
        XNonParRegionsChannel = Channel.value(xNonParRegions)
        Gatk4_HaplotypecallerX(bam.join(bai).combine(XNonParRegionsChannel).combine(Dragstr_model),
        referenceFasta, referenceFastaFai, referenceFastaDict, dbsnpVCF, dbsnpVCFIndex)

        //Haplotypecaller if gender is male or unknown.
        if (params.gender == "male" || params.gender == "unknown" ) {
            //YnonParRegions converted to Channel
            YNonParRegionsChannel = Channel.value(yNonParRegions).toList()
            Gatk4_HaplotypecallerY(bam.join(bai).combine(YNonParRegionsChannel).combine(Dragstr_model),
            referenceFasta, referenceFastaFai, referenceFastaDict, dbsnpVCF, dbsnpVCFIndex)
        }
    }

    //define VCF and index through a conditional statement.
    VCFs = xNonParRegions != [] && yNonParRegions != [] ? 
        params.gender == "male" || params.gender == "unknown" ?

            //This is the input if either the gender is male or unknown and if the regions are given.
            Gatk4_Haplotypecaller.out.vcf.join(Gatk4_HaplotypecallerX.out.vcf).join(Gatk4_HaplotypecallerY.out.vcf).join(
            (Gatk4_Haplotypecaller.out.tbi.join(Gatk4_HaplotypecallerX.out.tbi).join(Gatk4_HaplotypecallerY.out.tbi))) :

            //This is the input if the gender is female and if the regions are given.
            Gatk4_Haplotypecaller.out.vcf.join(Gatk4_HaplotypecallerX.out.vcf).join(
                (Gatk4_Haplotypecaller.out.tbi.join(Gatk4_HaplotypecallerX.out.tbi))) :

        //This is the input if the regions are not given.
        Gatk4_Haplotypecaller.out.vcf.join(Gatk4_Haplotypecaller.out.tbi)
    
    //Checks if regions are given and whether both gvcf and mergeVcf is set to true
    if (xNonParRegions != [] && yNonParRegions != [] && params.mergeVcf  && params.gvcf) {
        Gatk4_Combinegvcfs(VCFs, referenceFasta, referenceFastaFai, referenceFastaDict)
    }
    //Checks if regions are given and whether mergeVcf is set to true and gvcf is set to false.
    else if (xNonParRegions != [] && yNonParRegions != [] && params.mergeVcf && !params.gvcf) {
        Picard_Mergevcfs(VCFs)
    }
    
    //creating merged vcf or gvcf function that can be used in bfctools stats.
    mergedVcf = params.mergeVcf && !params.gvcf && xNonParRegions != [] && yNonParRegions != [] ? Picard_Mergevcfs.out.vcf :
        params.mergeVcf && params.gvcf && xNonParRegions != [] && yNonParRegions != [] ? Gatk4_Combinegvcfs.out.vcf.join(Gatk4_Combinegvcfs.out.tbi) :
        Gatk4_Haplotypecaller.out.vcf.join(Gatk4_Haplotypecaller.out.tbi)

    //bcftools stats
    Bcftools_Stats(mergedVcf, Bcfstats_regions, Bcfstats_targets, Bcfstats_samples, Bcfstats_exons, referenceFasta)

    //Emit output.
    emit:
    report = Bcftools_Stats.out.stats

}