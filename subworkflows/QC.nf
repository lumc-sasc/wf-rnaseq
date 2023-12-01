include { FASTQC as read_fastqc } from "../modules/fastqc/main.nf"
include { FASTQC as cutadapt_fastqc } from "../modules/fastqc/main.nf"

include { CUTADAPT as Cutadapt} from "../modules/cutadapt/main.nf"

workflow QCwf {
    take:
    read_list

    main:

    //convert all to inputchannels for process.
    read_listChannel = Channel.fromList(read_list)
    

    //runadapterclipping boolean
    boolean runAdapterClipping = params.adapterForward.size() > 0 || params.adapterReverse.size() > 0|| params.contaminations.size() > 0

    
    //run fastQC on read1 and if present read2
    read_fastqc(read_listChannel)

    

    //if cutadaptclipping is run, cutadapt is given
    if (runAdapterClipping) {
        Cutadapt(read_listChannel)
        cutadapt_fastqc(reads = Cutadapt.out.reads)
    
    }

    emit:
    reads = runAdapterClipping ? Cutadapt.out.reads : read_listChannel

    reports = runAdapterClipping ?
        [read_fastqc.out.html, read_fastqc.out.zip, cutadapt_fastqc.out.html, cutadapt_fastqc.out.zip, Cutadapt.out.log] :
        [read_fastqc.out.html, read_fastqc.out.zip]
}

