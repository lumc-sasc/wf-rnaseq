//Subworkflows are being included.
include {GATK4_SPLITNCIGARREADS as SplitNCigarReads} from "../modules/nf-core/gatk4/splitncigarreads/main.nf"
include {SAMTOOLS_INDEX as Samtools_Index} from "../modules/nf-core/samtools/index/main.nf"
include {PICARD_GATHERBAMFILES as GatherBamFiles_Ncigar} from "../modules/local/picard/gatherbamfiles/main.nf"
include {SAMTOOLS_INDEX as Samtools_Index_Gathered_NCigar} from "../modules/nf-core/samtools/index/main.nf"
include {GATK4_BASERECALIBRATOR as BaseRecalibrator} from "../modules/nf-core/gatk4/baserecalibrator/main.nf"
include {GATK4_GATHERBQSRREPORTS as GatherBqsrreports} from "../modules/nf-core/gatk4/gatherbqsrreports/main.nf"
include {GATK4_APPLYBQSR as ApplyBqsr} from "../modules/nf-core/gatk4/applybqsr/main.nf"
include {SAMTOOLS_INDEX as Samtools_Index_Bqsr} from "../modules/nf-core/samtools/index/main.nf"
include {SAMTOOLS_INDEX as Samtools_Index_Gathered} from "../modules/nf-core/samtools/index/main.nf"
include {PICARD_GATHERBAMFILES as GatherBamFiles} from "../modules/local/picard/gatherbamfiles/main.nf"

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
    //Conditional statement whether splitNCigar has to be executed.
    if (params.splitSplicedReads) {

        //Executes SplitNCigarReads, where reads are split if they contain Ns in their cigar string.
        SplitNCigarReads(bam.combine(scatters.flatten()), referenceFasta, referenceFastaFai, referenceFastaDict)
        Samtools_Index(SplitNCigarReads.out.bam)

        //Gathers the bamfiles based on sample so it can be used properly downstream.
        GatherBamFiles_Ncigar(SplitNCigarReads.out.bam.groupTuple().join(Samtools_Index.out.bai.groupTuple()))
        Samtools_Index_Gathered_NCigar(GatherBamFiles_Ncigar.out.bam)
    }

    //Input for bam processes created. Can be from SplitNcigar or the bam that is imported from the main workfklow.
    params.splitSplicedReads ? GatherBamFiles_Ncigar.out.bam.join(Samtools_Index_Gathered_NCigar.out.bai).combine(scatters.flatten()).set{BaseRecalibrator_input}
    : bam.combine(scatters.flatten()).set{BaseRelcaibrator_input}

    //Base recalibration
    BaseRecalibrator(BaseRecalibrator_input, referenceFasta[1], referenceFastaFai[1],
    referenceFastaDict[1], dbsnpVCF[1], dbsnpVCFIndex[1])

    //Gathering of Bqsr if there are 2 or more scatters.
    GatherBqsrreports(BaseRecalibrator.out.table.groupTuple())


    //BQSR input created and given to ApplyBqsr
    Bqsr_input = params.splitSplicedReads ? SplitNCigarReads.out.bam.join(Samtools_Index.out.bai).join(GatherBqsrreports.out.table
    ).combine(scatters.flatten()) : bam.join(GatherBqsrreports.out.table).combine(scatters.flatten())
    //run ApplyBQSR and the samtools index to create the bam index of ApplyBqsr
    ApplyBqsr(Bqsr_input,referenceFasta[1],referenceFastaFai[1],referenceFastaDict[1])
    Samtools_Index_Bqsr(ApplyBqsr.out.bam)

    //Gather the bam files based on the sample
    GatherBamFiles(ApplyBqsr.out.bam.groupTuple().join(Samtools_Index_Bqsr.out.bai.groupTuple()))
    Samtools_Index_Gathered(GatherBamFiles.out.bam)
    //Emit the output.
    emit:
    bam = GatherBamFiles.out.bam
    bai = Samtools_Index_Gathered.out.bai
    


    

}