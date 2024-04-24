
//Processes are loaded in.
include { FASTQC as read_fastqc } from "../modules/nf-core/fastqc/main.nf"
include { FASTQC as cutadapt_fastqc } from "../modules/nf-core/fastqc/main.nf"

include { CUTADAPT as Cutadapt} from "../modules/nf-core/cutadapt/main.nf"

//Start of workflow
workflow QCwf {
    //Input of workflow are given.
    take:
    read_list

    //Main part of the workflow
    main:

    //Looks if any of the adapters or contaminations are present. If it is present, it will set runAdapterClipping to true, else it will set to false.
    boolean runAdapterClipping = params.adapterForward.size() > 0 || params.adapterReverse.size() > 0|| params.contaminations.size() > 0

    
    //Does quality control on raw sequence data.
    read_fastqc(read_list)

    

    //if runAdapterClipping is true, it will run cutadapt and fastqc of cutadapt.
    if (runAdapterClipping) {
        //Trims reads based on the adapters or contaminations.
        Cutadapt(read_list)

        //Does quality control on the trimmed sequence data.
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

