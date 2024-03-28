include {GATK4_SPLITNCIGARREADS as SplitNCigarReads} from "../custom_modules/gatk4/SplitNCigarReads/main.nf"
include {SAMTOOLS_INDEX as Samtools_Index} from "../modules/samtools/index/main.nf"
include {GATK4_BASERECALIBRATOR as BaseRecalibrator} from "../modules/gatk4/baserecalibrator/main.nf"
include {GATK4_GATHERBQSRREPORTS as GatherBqsrreports} from "../modules/gatk4/gatherbqsrreports/main.nf"
include {GATK4_APPLYBQSR as ApplyBqsr} from "../modules/gatk4/applybqsr/main.nf"
include {SAMTOOLS_INDEX as Samtools_Index_Bqsr} from "../modules/samtools/index/main.nf"
include {PICARD_GATHERBAMFILES as GatherBamFiles} from "../custom_modules/picard/gatherbamfiles/main.nf"

//Start of workflow
workflow Preprocesswf {
    //Take input
    take:
    bam
    dbsnpVCF
    dbsnpVCFIndex
    referenceFasta
    referenceFastaFai
    referenceFastaDict
    scatters

    //Main part
    main:
    //Checks if the reads are spliced.
    bam.combine(scatters).combine(scatters.size()).map { instance ->
        if (instance[-1] > 1) {
        item = [instance[0],instance[1], instance[2], instance.subList(3, instance.size() -1)]
        }
        else {
            item = [[id: "empty"], [], [], []]
        }
        return item
    }.set{SplitNCigarReads_input}


    if (params.splitSplicedReads) {
        SplitNCigarReads(SplitNCigarReads_input, referenceFasta[1], referenceFastaFai[1], referenceFastaDict[1])
        Samtools_Index(SplitNCigarReads.out.bam)
        
        //Input for bam processes created. Can be from SplitNcigar or the bam that is imported from the main workfklow.
        SplitNCigarReads.out.bam.join(Samtools_Index.out.bai).combine(scatters).join(bam).map{ instance ->
            if (instance[-2] > 1) {
            item = [instance[0],instance[1], instance[2], instance.subList(3, instance.size() -1)]
            }
            else {
                item = [[]]
            }
        }.set{BaseRecalibrator_input}

        //Base recalibration
        BaseRecalibrator(BaseRecalibrator_input, referenceFasta[1], referenceFastaFai[1],
        referenceFastaDict[1], dbsnpVCF, dbsnpVCFIndex)
    }

    //Gathering of Bqsr if there are 2 or more scatters.
    if (params.scatter_size > 1) {
        GatherBqsrreports(BaseRecalibrator.out.table)

    }
    //if scattered, use gatherBqsr reports, otherwise Baserecalibrator
    Recalibration_report = params.scatter_size > 1 ? GatherBqsrreports.out.table : BaseRecalibrator.out.table

    
    //BQSR input created and given to ApplyBqsr
    Bqsr_input = params.splitSplicedReads ? SplitNCigarReads.out.bam.join(Samtools_Index.out.bai).join(Recalibration_report
    ).combine(scatters) : bam.join(Recalibration_report).combine(scatters)

    //run ApplyBQSR and the samtools index to create the bam index of ApplyBqsr
    ApplyBqsr(Bqsr_input,referenceFasta[1],referenceFastaFai[1],referenceFastaDict[1])
    Samtools_Index_Bqsr(ApplyBqsr.out.bam)

    //if there are 2 or more scatters, gather the bam files
    if (params.scatter_size > 1) {
        GatherBamFiles(ApplyBqsr.out.bam, Samtools_Index_Bqsr.out.bai)

    }

    emit:
    bam = params.scatter_size > 1 ? GatherBamFiles.out.bam : ApplyBqsr.out.bam
    bai = params.scatter_size > 1 ? GatherBamFiles.out.bai : Samtools_Index_Bqsr.out.bai
    


    

}