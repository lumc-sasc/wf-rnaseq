
//Processes/Modules are loaded in.
include { FASTQC as read_fastqc } from "../modules/fastqc/main.nf"
include { FASTQC as cutadapt_fastqc } from "../modules/fastqc/main.nf"

include { CUTADAPT as Cutadapt} from "../modules/cutadapt/main.nf"

//Start of workflow
workflow QCwf {
    //Input of workflow are given.
    take:
    read_list

    //Main part of the workflow
    main:

    //runadapterclipping boolean
    boolean runAdapterClipping = params.adapterForward.size() > 0 || params.adapterReverse.size() > 0|| params.contaminations.size() > 0

    
    //run fastQC on read1 and if present read2
    read_fastqc(read_list)

    

    //if cutadaptclipping is run, cutadapt is given
    if (runAdapterClipping) {
        Cutadapt(read_list)
        cutadapt_fastqc(reads = Cutadapt.out.reads)
    
    }

    //combines all the reports from fastqc and if adapter is run cutadapt aswell.
    reports = runAdapterClipping ?
        read_fastqc.out.html.join(read_fastqc.out.zip).join(cutadapt_fastqc.out.html).join(cutadapt_fastqc.out.zip).join(Cutadapt.out.log) :
        read_fastqc.out.html.join(read_fastqc.out.zip)
        

    //emits the output. 
    emit:
    reads = runAdapterClipping ? Cutadapt.out.reads : read_list

    reports = reports
}

