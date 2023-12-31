include {GATK4_HAPLOTYPECALLER as Gatk4_Haplotypecaller} from "../../modules/gatk4/haplotypecaller/main.nf"
include {GATK4_HAPLOTYPECALLER as Gatk4_HaplotypecallerX} from "../../modules/gatk4/haplotypecaller/main.nf"
include {GATK4_HAPLOTYPECALLER as Gatk4_HaplotypecallerY} from "../../modules/gatk4/haplotypecaller/main.nf"
include {GATK4_COMBINEGVCFS as Gatk4_Combinegvcfs} from "../../modules/gatk4/combinegvcfs/main.nf"
include {PICARD_MERGEVCFS as Picard_Mergevcfs} from "../../custom_modules/picard/Mergevcfs/main.nf"
include {BCFTOOLS_STATS as Bcftools_Stats} from "../../modules/bcftools/stats/main.nf"



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

workflow SingleSampleCallingwf {
    take:
    bam
    bai
    referenceFasta
    referenceFastaFai
    referenceFastaDict
    dbsnpVCF
    dbsnpVCFIndex
    XNonParRegions
    YNonParRegions
    autosomalregions

    main:
    //Haplotypecaller
    Gatk4_Haplotypecaller(bam.join(bai).combine(autosomalregions).combine(Dragstr_model),
    referenceFasta[1], referenceFastaFai[1], referenceFastaDict[1], dbsnpVCF, dbsnpVCFIndex)

    //Haplotypecaller if Xnonparregions and YnonparsRegions are given
    if (XNonParRegions != null && YNonParRegions != null) {
        //XnonParRegions converted to Channel
        XNonParRegionsChannel = Channel.value(XNonParRegions)
        Gatk4_HaplotypecallerX(bam.join(bai).combine(XNonParRegionsChannel).combine(Dragstr_model),
        referenceFasta[1], referenceFastaFai[1], referenceFastaDict[1], dbsnpVCF, dbsnpVCFIndex)

        //Haplotypecaller if gender is male or unknown.
        if (params.gender == "male" || params.gender == "unknown" ) {
            //YnonParRegions converted to Channel
            YNonParRegionsChannel = Channel.value(YNonParRegions)
            Gatk4_HaplotypecallerY(bam.join(bai).combine(YNonParRegionsChannel).combine(Dragstr_model),
            referenceFasta[1], referenceFastaFai[1], referenceFastaDict[1], dbsnpVCF, dbsnpVCFIndex)
        }
    }

    //define VCF and index
    VCFs = XNonParRegions != null && YNonParRegions != null ? 
        params.gender == "male" || params.gender == "unknown" ?

            //if there are regions on X and Y and if gender is male or unknown
            Gatk4_Haplotypecaller.out.vcf.groupTuple(Gatk4_HaplotypecallerX.out.vcf).groupTuple(Gatk4_HaplotypecallerY.out.vcf).join(
            (Gatk4_Haplotypecaller.out.tbi.groupTuple(Gatk4_HaplotypecallerX.out.tbi).groupTuple(Gatk4_HaplotypecallerY.out.tbi))) :

            //if there are regions on X and Y but gender is not male or unknown
            Gatk4_Haplotypecaller.out.vcf.groupTuple(Gatk4_HaplotypecallerX.out.vcf).join(
                (Gatk4_Haplotypecaller.out.tbi.groupTuple(Gatk4_HaplotypecallerX.out.tbi))) :

        //if there are no regions on X and Y.
        Gatk4_Haplotypecaller.out.vcf.join(Gatk4_Haplotypecaller.out.tbi)
    

    if (XNonParRegions != null && YNonParRegions != null && params.mergeVcf && params.scatter_size > 1 && params.gvcf) {
        Gatk4_Combinegvcfs(VCFs, referenceFasta, referenceFastaFai, referenceFastaDict)
    }
    else if (XNonParRegions != null && YNonParRegions != null && params.mergeVcf && params.scatter_size > 1 && !params.gvcf) {
        Picard_Mergevcfs(VCFs)
    }
    
    //creating merged vcf or gvcf function that can be used in bfctools stats.
    mergedVcf = params.mergeVcf && params.scatter_size > 1 && !params.gvcf ? Picard_Mergevcfs.out.vcf :
        params.mergeVcf && params.scatter_size > 1 && params.gvcf ? Gatk4_Combinegvcfs.out.vcf.join(Gatk4_Combinegvcfs.out.tbi) :
        Gatk4_Haplotypecaller.out.vcf.join(Gatk4_Haplotypecaller.out.tbi)

    //bcftools stats
    Bcftools_Stats(mergedVcf, Bcfstats_regions, Bcfstats_targets, Bcfstats_samples, Bcfstats_exons, referenceFasta)

    emit:
    report = Bcftools_Stats.out.stats

}